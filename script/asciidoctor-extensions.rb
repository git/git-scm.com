require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/converter/html5'
require 'parslet'
# for parslet, see https://kschiess.github.io/parslet/parser.html

module Git
  module Documentation
    class AdocSynopsisQuote < Parslet::Parser
      # parse a string like "git add -p [--root=<path>]" as series of
      # tokens keywords, grammar signs and placeholders where
      # placeholders are UTF-8 words separated by '-', enclosed in '<'
      # and '>'. The >> indicates a "simple sequence", for example
      # str('...') >> match('\]|$').present? means "first match three
      # periods, then ensure that they are either followed by a
      # closing bracket or they are at the end.
      rule(:space) { match('[\s\t\n ]').repeat(1) }
      rule(:space?) { space.maybe }
      rule(:keyword) { match('[-a-zA-Z0-9:+=~@,\./_\^\$\'"\*%!{}#]').repeat(1) }
      rule(:placeholder) { str('<') >> match('[[:word:]]|-').repeat(1) >> str('>') }
      rule(:opt_or_alt) { match('[\[\] |()]') >> space? }
      rule(:ellipsis) { str('...') >> match('\]|$').present? }
      rule(:grammar) { opt_or_alt | ellipsis }
      rule(:ignore) { str('`') }

      rule(:token) do
        grammar.as(:grammar) | placeholder.as(:placeholder) | space.as(:space) |
          ignore.as(:ignore) | keyword.as(:keyword)
      end
      rule(:tokens) { token.repeat(1) }
      root(:tokens)
    end

    class EscapedSynopsisQuote < AdocSynopsisQuote
      rule(:placeholder) { str('&lt;') >> match('[[:word:]]|-').repeat(1) >> str('&gt;') }
    end

    class SynopsisQuoteBase < Parslet::Transform
      rule(grammar: simple(:grammar)) { grammar.to_s }
      rule(space: simple(:space)) { space.to_s }
      rule(ignore: simple(:ignore)) { '' }
    end

    class SynopsisQuoteToAdoc < SynopsisQuoteBase
      rule(keyword: simple(:keyword)) { "{empty}`#{keyword}`{empty}" }
      rule(placeholder: simple(:placeholder)) { "__#{placeholder}__" }
    end

    class SynopsisQuoteToHtml5 < SynopsisQuoteBase
      rule(keyword: simple(:keyword)) { "<code>#{keyword}</code>" }
      rule(placeholder: simple(:placeholder)) { "<em>#{placeholder}</em>" }
    end

    class SynopsisConverter
      def convert(parslet_parser, parslet_transform, reader, logger = nil)
        reader.lines.map do |l|
          parslet_transform.apply(parslet_parser.parse(l)).join
        end.join("\n")
      rescue Parslet::ParseFailed
        logger.info "synopsis parsing failed for '#{reader.lines.join(' ')}'"
        reader.lines.map do |l|
          parslet_transform.apply(placeholder: l)
        end.join("\n")
      end
    end

    class SynopsisBlock < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :synopsis
      parse_content_as :simple

      def process(parent, reader, attrs)
        outlines = SynopsisConverter.new.convert(
          AdocSynopsisQuote.new,
          SynopsisQuoteToAdoc.new,
          reader,
          parent.document.logger
        )
        create_block parent, :verse, outlines, attrs
      end
    end

    # register a html5 converter that takes in charge
    # to convert monospaced text into Git style synopsis
    class GitHTMLConverter < Asciidoctor::Converter::Html5Converter
      extend Asciidoctor::Converter::Config
      register_for 'html5'

      def convert_inline_quoted(node)
        if node.type == :monospaced
          t = SynopsisConverter.new.convert(
            EscapedSynopsisQuote.new,
            SynopsisQuoteToHtml5.new,
            node.text,
            node.document.logger
          )
          "<span class='synopsis'>#{t}</span>"
        else
          open, close, tag = QUOTE_TAGS[node.type]
          if node.id
            class_attr = node.role ? %( class="#{node.role}") : ''
            if tag
              %(#{open.chop} id="#{node.id}"#{class_attr}>#{node.text}#{close})
            else
              %(<span id="#{node.id}"#{class_attr}>#{open}#{node.text}#{close}</span>)
            end
          elsif node.role
            if tag
              %(#{open.chop} class="#{node.role}">#{node.text}#{close})
            else
              %(<span class="#{node.role}">#{open}#{node.text}#{close}</span>)
            end
          else
            %(#{open}#{node.text}#{close})
          end
        end
      end
    end
  end
end

Asciidoctor::Extensions.register do
  block Git::Documentation::SynopsisBlock
end

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/converter/html5'

module Git
  module Documentation
    class SynopsisBlock < Asciidoctor::Extensions::BlockProcessor

      use_dsl
      named :synopsis
      parse_content_as :simple

      def process parent, reader, attrs
        outlines = reader.lines.map do |l|
          l.gsub(/(\.\.\.?)([^\]$.])/, '`\1`\2')
           .gsub(%r{([\[\] |()>]|^)([-a-zA-Z0-9:+=~@,/_^\$]+)}, '\1{empty}`\2`{empty}')
           .gsub(/(<([[:word:]]|[-0-9.])+>)/, '__\\1__')
           .gsub(']', ']{empty}')
        end
        create_block parent, :verse, outlines, attrs
      end
    end

    # register a html5 converter that takes in charge to convert monospaced text into Git style synopsis
    class GitHTMLConverter < Asciidoctor::Converter::Html5Converter

      extend Asciidoctor::Converter::Config
      register_for 'html5'

      def convert_inline_quoted node
        if node.type == :monospaced
          node.text.gsub(/(\.\.\.?)([^\]$.])/, '<code>\1</code>\2')
              .gsub(%r{([\[\s|()>.]|^|\]|&gt;)(\.?([-a-zA-Z0-9:+=~@,/_^\$]+\.{0,2})+)}, '\1<code>\2</code>')
              .gsub(/(&lt;([[:word:]]|[-0-9.])+&gt;)/, '<em>\1</em>')
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

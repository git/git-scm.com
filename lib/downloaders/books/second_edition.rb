# rubocop:disable Style/FrozenStringLiteralComment
require "nokogiri"
require "pathname"

require_relative "../../octokit_configuration.rb"

module Downloaders
  module Books
    class SecondEdition
      # The chapter files are historically located in book/<chapter_name>/1-<chapter_name>.asc
      # The new localisation of these files are at the root of the project
      CHAPTER_FILES = /(book\/[01A-C].*\/1-[^\/]*?\.asc|(?:ch[0-9]{2}|[ABC])-[^\/]*?\.asc)/

      CHAPTER_NAVIGATION = '<div id="nav"><a href="[[nav-prev]]">prev</a> | <a href="[[nav-next]]">next</a></div>'.freeze

      TRANSLATIONS = {
        "be"    => "progit/progit2-be",
        "bg"    => "progit/progit2-bg",
        "cs"    => "progit-cs/progit2-cs",
        "de"    => "progit-de/progit2",
        "en"    => "progit/progit2",
        "es"    => "progit/progit2-es",
        "fa"    => "progit2-fa/progit2",
        "fr"    => "progit/progit2-fr",
        "gr"    => "progit2-gr/progit2",
        "id"    => "progit/progit2-id",
        "it"    => "progit/progit2-it",
        "ja"    => "progit/progit2-ja",
        "ko"    => "progit/progit2-ko",
        "mk"    => "progit2-mk/progit2",
        "nl"    => "progit/progit2-nl",
        "pl"    => "progit2-pl/progit2-pl",
        "pt-br" => "progit2-pt-br/progit2",
        "ru"    => "progit/progit2-ru",
        "sl"    => "progit/progit2-sl",
        "sr"    => "progit/progit2-sr",
        "tl"    => "progit2-tl/progit2",
        "tr"    => "progit/progit2-tr",
        "uk"    => "progit/progit2-uk",
        "uz"    => "progit/progit2-uz",
        "zh"    => "progit/progit2-zh",
        "zh-tw" => "progit/progit2-zh-tw"
      }.freeze

      class << self
        def generate_for(language)
          unless TRANSLATIONS.key?(language)
            raise StandardError, "#{language} is not a valid book translation"
          end

          new(language).perform
        end
      end

      attr_reader :language, :octokit, :repo, :repo_head, :template_dir

      def initialize(language)
        @language = language

        @octokit      = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"], auto_paginate: true)
        @repo         = TRANSLATIONS[language]
        @repo_head    = @octokit.ref(repo, "heads/master").object[:sha]
        @template_dir = Rails.root.join("templates").to_s
      end

      def perform
        Rails.logger.info("Creating Book for #{language} from #{repo}")

        progit = retrieve_contents_of("progit.asc")

        chapters = {}

        appendix = 0
        chapter  = 0
        section  = 0

        progit.scan(CHAPTER_FILES).flatten.each_with_index do |filename, index|
          # select the chapter files
          if filename =~ /(book\/[01].*\/1-[^\/]*\.asc|ch[0-9]{2}-.*\.asc)/
            chapter += 1

            chapters ["ch#{section}"] = ["chapter", chapter, filename]

            section += 1
          end

          # detect the appendices
          if filename =~ /(book\/[ABC].*\.asc|[ABC].*\.asc)/
            appendix += 1

            chapters ["ch#{section}"] = ["appendix", appendix, filename]

            section += 1
          end
        end

        # we strip the includes that don't match the chapters we want to include
        initial_content = progit.gsub(/include::(.*\.asc)\[\]/) do |match|
          if Regexp.last_match(1) =~ CHAPTER_FILES
            match
          else
            ""
          end
        end

        content = expand(initial_content, "progit.asc")

        # revert internal links decorations for ebooks
        content.gsub!(/<<.*?\#(.*?)>>/, "<<\\1>>")

        asciidoc = Asciidoctor::Document.new(content, template_dir: template_dir, attributes: { "compat-mode" => true})
        html     = asciidoc.render
        alldoc   = Nokogiri::HTML(html)
        number   = 1

        # Establish the connection
        ApplicationRecord.connection

        Book.transaction do
          Book.destroy_all(edition: 2, code: language)
          book = Book.create!(edition: 2, code: language, ebook_html: repo_head)

          alldoc.xpath("//div[@class='sect1']").each_with_index do |entry, index|
            chapter_title = entry.at("h2").content

            unless chapters.key?("ch#{index}")
              Rails.logger.error("Not including #{chapter_title}")
              break
            end

            chapter_type, chapter_number, _filename = chapters ["ch#{index}"]
            chapter = entry

            next if chapter_title.nil?
            next if chapter_number.nil?

            number = chapter_number
            if chapter_type == "appendix"
              number = 100 + chapter_number
            end

            pretext = entry.search("div[@class=sectionbody]/div/p").to_html
            id_xref = chapter.at("h2").attribute("id").to_s

            schapter = book.chapters.create!(
              chapter_number: chapter_number,
              chapter_type:   chapter_type,
              number:         number,
              title:          chapter_title.to_s,
              sha:            book.ebook_html
            )

            # create xref
            csection = schapter.sections.first_or_create!(number: 1)
            xref     = book.xrefs.first_or_create!(name: id_xref, section: csection)

            section = 1
            chapter.search("div[@class=sect2]").each do |sec|
              id_xref = sec.at("h3").attribute("id").to_s

              section_title = sec.at("h3").content

              html = sec.inner_html.to_s + CHAPTER_NAVIGATION

              html.gsub!("<h3", "<h2")
              html.gsub!(/\/h3>/, "/h2>")
              html.gsub!("<h4", "<h3")
              html.gsub!(/\/h4>/, "/h3>")
              html.gsub!("<h5", "<h4")
              html.gsub!(/\/h5>/, "/h4>")

              if xlink = html.scan(/href=\"1-.*?\.html\#(.*?)\"/)
                xlink.each do |link|
                  xref = link.first
                  html.gsub!(/href=\"1-.*?\.html\##{xref}\"/, "href=\"ch00/#{xref}\"") rescue nil
                end
              end

              if xlink = html.scan(/href=\"\#(.*?)\"/)
                xlink.each do |link|
                  xref = link.first
                  html.gsub!(/href=\"\##{xref}\"/, "href=\"ch00/#{xref}\"") rescue nil
                end
              end

              if subsec = html.scan(/<img src="(.*?)"/)
                subsec.each do |sub|
                  sub = sub.first
                  html.gsub!(/<img src="#{sub}"/, "<img src=\"/book/en/v2/#{sub}\"") rescue nil
                end
              end

              Rails.logger.info("\t\t#{chapter_type} #{chapter_number}.#{section} : #{chapter_title} . #{section_title} - #{html.size}")

              csection = schapter.sections.where(number: section).first_or_create!
              csection.update_attributes!(title: section_title.to_s, html: (pretext + html))

              xref = book.xrefs.create!(name: id_xref, section: csection)

              # record all the xrefs
              (sec.search(".//*[@id]")).each do |id|
                id_xref = id.attribute("id").to_s
                xref    = book.xrefs.create!(name: id_xref, section: csection)
              end

              section += 1
              pretext = ""
            end
          end

          begin
            release = octokit.latest_release(repo)

            get_brower_download_url_for_type = -> (content_type) do
              release_asset = release.assets.select do |asset|
                asset.content_type == content_type
              end.first

              if release_asset
                return release_asset.browser_download_url
              end

              nil
            end

            book.update_attributes!(
              ebook_pdf:  get_brower_download_url_for_type.call("application/pdf"),
              ebook_epub: get_brower_download_url_for_type.call("application/epub+zip"),
              ebook_mobi: get_brower_download_url_for_type.call("application/x-mobipocket-ebook")
            )
          rescue Octokit::NotFound => err
            Rails.logger.error(err.message)
          end
        end
      end

      private def expand(content, path)
        content.gsub(/include::(\S+)\[\]/) do |line|
          if File.dirname(path) == "."
            new_fname = Regexp.last_match(1)
          else
            new_fname = (Pathname.new(path).dirname + Pathname.new(Regexp.last_match(1))).cleanpath.to_s
          end

          new_content = retrieve_contents_of(new_fname)

          if new_content
            expand(new_content.gsub("\xEF\xBB\xBF".force_encoding("UTF-8"), ""), new_fname)
          else
            Rails.logger.error("#{new_fname} could not be resolved for expansion")
          end
        end
      end

      private def retrieve_contents_of(filepath)
        response = octokit.contents(repo, path: filepath)
        content  = Base64.decode64(response.content)

        content.force_encoding("UTF-8")
      end
    end
  end
end

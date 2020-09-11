# rubocop:disable Style/FrozenStringLiteralComment

require "nokogiri"
require "octokit"
require "pathname"

def expand(content, path, &get_content)
  content.gsub(/include::(\S+)\[\]/) do |line|
    if File.dirname(path)=="."
      new_fname = $1
    else
      new_fname = (Pathname.new(path).dirname + Pathname.new($1)).cleanpath.to_s
    end
    new_content = get_content.call(new_fname)
    if new_content
      expand(new_content.gsub("\xEF\xBB\xBF".force_encoding("UTF-8"), ""), new_fname) { |c| get_content.call (c) }
    else
      puts "#{new_fname} could not be resolved for expansion"
      ""
    end
  end
end

desc "Reset book html to trigger re-build"
task reset_book2: :environment do
    Book.where(edition: 2).each do |book|
        book.ebook_html = "0000000000000000000000000000000000000000"
        book.save
    end
end

def genbook(code, &get_content)
  template_dir = File.join(Rails.root, "templates")

  nav = '<div id="nav"><a href="[[nav-prev]]">prev</a> | <a href="[[nav-next]]">next</a></div>'

  progit = get_content.call("progit.asc")

  chapters = {}
  appnumber = 0
  chnumber = 0
  secnumber = 0
  ids = {}

  # The chapter files are historically located in book/<chapter_name>/1-<chapter_name>.asc
  # The new localisation of these files are at the root of the project
  chapter_files = /(book\/[01A-C].*\/1-[^\/]*?\.asc|(?:ch[0-9]{2}|[ABC])-[^\/]*?\.asc)/
  chaps = progit.scan(chapter_files).flatten

  chaps.each_with_index do |filename, index|
    # select the chapter files
    if filename =~ /(book\/[01].*\/1-[^\/]*\.asc|ch[0-9]{2}-.*\.asc)/
      chnumber += 1
      chapters ["ch#{secnumber}"] = ["chapter", chnumber, filename]
      secnumber += 1
    end
    # detect the appendices
    if filename =~ /(book\/[ABC].*\.asc|[ABC].*\.asc)/
      appnumber += 1
      chapters ["ch#{secnumber}"] = ["appendix", appnumber, filename]
      secnumber += 1
    end
  end

  # we strip the includes that don't match the chapters we want to include
  initial_content = progit.gsub(/include::(.*\.asc)\[\]/) do |match|
    if $1 =~ chapter_files
      match
    else
      ""
    end
  end

  content = expand(initial_content, "progit.asc") { |filename| get_content.call(filename) }
  # revert internal links decorations for ebooks
  content.gsub!(/<<.*?\#(.*?)>>/, "<<\\1>>")

  asciidoc = Asciidoctor::Document.new(content, template_dir: template_dir, attributes: { "compat-mode" => true})
  html = asciidoc.render
  alldoc = Nokogiri::HTML(html)
  number = 1

  Book.destroy_all(edition: 2, code: code)
  book = Book.create(edition: 2, code: code)

  alldoc.xpath("//div[@class='sect1']").each_with_index do |entry, index|
    chapter_title = entry.at("h2").content
    if !chapters["ch#{index}"]
      puts "not including #{chapter_title}\n"
      break
    end
    chapter_type, chapter_number, filename = chapters ["ch#{index}"]
    chapter = entry

    next if !chapter_title
    next if !chapter_number

    number = chapter_number
    if chapter_type == "appendix"
      number = 100 + chapter_number
    end

    pretext = entry.search("div[@class=sectionbody]/div/p").to_html
    id_xref = chapter.at("h2").attribute("id").to_s

    schapter = book.chapters.where(number: number).first_or_create
    schapter.title = chapter_title.to_s
    schapter.chapter_type = chapter_type
    schapter.chapter_number = chapter_number
    schapter.sha = book.ebook_html
    schapter.save

    # create xref
    csection = schapter.sections.where(number: 1).first_or_create
    xref = Xref.where(book_id: book.id, name: id_xref).first_or_create
    xref.section = csection
    xref.save

    section = 1
    chapter.search("div[@class=sect2]").each do |sec|

      id_xref = sec.at("h3").attribute("id").to_s

      section_title = sec.at("h3").content

      html = sec.inner_html.to_s + nav

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

      puts "\t\t#{chapter_type} #{chapter_number}.#{section} : #{chapter_title} . #{section_title} - #{html.size}"

      csection = schapter.sections.where(number: section).first_or_create
      csection.title = section_title.to_s
      csection.html = pretext + html
      csection.save

      xref = Xref.where(book_id: book.id, name: id_xref).first_or_create
      xref.section = csection
      xref.save

      # record all the xrefs
      (sec.search(".//*[@id]")).each do |id|
        id_xref = id.attribute("id").to_s
        xref = Xref.where(book_id: book.id, name: id_xref).first_or_create
        xref.section = csection
        xref.save
      end

      section += 1
      pretext = ""
    end
  end
  book.sections.each do |section|
    section.set_slug
    section.save
  end
end

desc "Generate book html directly from git repo"
task remote_genbook2: :environment do
  @octokit = Octokit::Client.new(login: ENV["API_USER"], password: ENV["API_PASS"])

  if ENV["GENLANG"]
    books = Book.all_books.select { |code, repo| code == ENV["GENLANG"] }
  else
    books = Book.all_books.select do |code, repo|
      repo_head = @octokit.commit(repo, "HEAD").commit.sha
      book = Book.where(edition: 2, code: code).first_or_create
      repo_head != book.ebook_html
    end
  end

  books.each do |code, repo|
    begin
      blob_content = Hash.new do |blobs, sha|
        content = Base64.decode64(@octokit.blob(repo, sha, encoding: "base64").content)
        blobs[sha] = content.force_encoding("UTF-8")
      end
      repo_head = @octokit.commit(repo, "HEAD").commit
      repo_tree = @octokit.tree(repo, repo_head.tree.sha, recursive: true)
      Book.transaction do
        genbook(code) do |filename|
          file_handle = repo_tree.tree.detect { |tree| tree[:path] == filename }
          if file_handle
            blob_content[file_handle[:sha]]
          end
        end

        book = Book.where(edition: 2, code: code).first_or_create
        book.ebook_html = repo_head.sha

        begin
          rel = @octokit.latest_release(repo)
          get_url =   -> (content_type) do
            asset = rel.assets.select { |asset| asset.content_type==content_type }.first
            if asset
              asset.browser_download_url
            else
              nil
            end
          end
          book.ebook_pdf  = get_url.call("application/pdf")
          book.ebook_epub = get_url.call("application/epub+zip")
          book.ebook_mobi  = get_url.call("application/x-mobipocket-ebook")
        rescue Octokit::NotFound
          book.ebook_pdf  = nil
          book.ebook_epub = nil
          book.ebook_mobi  = nil
        end

        book.save
      end
    rescue StandardError => err
      puts err.message
    end
  end
end

desc "Generate book html directly from git repo"
task local_genbook2: :environment do
  if (ENV["GENLANG"] && ENV["GENPATH"])
    genbook(ENV["GENLANG"]) do |filename|
      File.open(File.join(ENV["GENPATH"], filename), "r") { |infile| File.read(infile) }
    end
  end
end

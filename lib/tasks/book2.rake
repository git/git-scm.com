require 'zip'
require 'nokogiri'
require 'octokit'
require 'pathname'

def expand(content, path, &get_content)
  content.gsub(/include::(\S+)\[\]/) do |line|
    if File.dirname(path)=="."
      new_fname = $1
    else
      new_fname = (Pathname.new(path).dirname + Pathname.new($1)).cleanpath.to_s
    end
    new_content = get_content.call(new_fname)
    if new_content
      expand(new_content.gsub("\xEF\xBB\xBF".force_encoding("UTF-8"), ''), new_fname) {|c| get_content.call (c)}
    else
      puts "#{new_fname} could not be resolved for expansion"
      ""
    end
  end
end

desc "Reset book html to trigger re-build"
task :reset_book2 => :environment do
    Book.where(:edition => 2).each do |book|
        book.ebook_html = '0000000000000000000000000000000000000000'
        book.save
    end
end

def genbook (code, &get_content)
  template_dir = File.join(Rails.root, 'templates')

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

  chaps.each_with_index do |filename, index |
    # select the chapter files
    if filename =~ /(book\/[01].*\/1-[^\/]*\.asc|ch[0-9]{2}-.*\.asc)/
      chnumber += 1
      chapters ["ch#{secnumber}"] = ['chapter', chnumber, filename]
      secnumber += 1
    end
    # detect the appendices
    if filename =~ /(book\/[ABC].*\.asc|[ABC].*\.asc)/
      appnumber += 1
      chapters ["ch#{secnumber}"] = ['appendix', appnumber, filename]
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

  asciidoc = Asciidoctor::Document.new(content,template_dir: template_dir, attributes: { 'compat-mode' => true})
  html = asciidoc.render
  alldoc = Nokogiri::HTML(html)
  number = 1

  book = Book.where(:edition => 2, :code => code).first_or_create

  alldoc.xpath("//div[@class='sect1']").each_with_index do |entry, index |
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
    if chapter_type == 'appendix'
      number = 100 + chapter_number
    end

    pretext = entry.search("div[@class=sectionbody]/div/p").to_html
    id_xref = chapter.at("h2").attribute('id').to_s

    schapter = book.chapters.where(:number => number).first_or_create
    schapter.title = chapter_title.to_s
    schapter.chapter_type = chapter_type
    schapter.chapter_number = chapter_number
    schapter.sha = book.ebook_html
    schapter.save

    # create xref
    csection = schapter.sections.where(:number => 1).first_or_create
    xref = Xref.where(:book_id => book.id, :name => id_xref).first_or_create
    xref.section = csection
    xref.save

    section = 1
    chapter.search("div[@class=sect2]").each do |sec|

      id_xref = sec.at("h3").attribute('id').to_s

      section_title = sec.at("h3").content

      html = sec.inner_html.to_s + nav

      html.gsub!('<h3', '<h2')
      html.gsub!(/\/h3>/, '/h2>')
      html.gsub!('<h4', '<h3')
      html.gsub!(/\/h4>/, '/h3>')
      html.gsub!('<h5', '<h4')
      html.gsub!(/\/h5>/, '/h4>')

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

      csection = schapter.sections.where(:number => section).first_or_create
      csection.title = section_title.to_s
      csection.html = pretext + html
      csection.save

      xref = Xref.where(:book_id => book.id, :name => id_xref).first_or_create
      xref.section = csection
      xref.save

      # record all the xrefs
      (sec.search(".//*[@id]")).each do |id|
        id_xref = id.attribute('id').to_s
        xref = Xref.where(:book_id => book.id, :name => id_xref).first_or_create
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
task :remote_genbook2 => :environment do
  @octokit = Octokit::Client.new(:login => ENV['API_USER'], :password => ENV['API_PASS'])
  all_books = {
    "be" => "progit/progit2-be",
    "bg" => "progit/progit2-bg",
    "cs" => "progit-cs/progit2-cs",
    "de" => "progit-de/progit2",
    "en" => "progit/progit2",
    "es" => "progit/progit2-es",
    "fr" => "progit/progit2-fr",
    "gr" => "progit2-gr/progit2",
    "id" => "progit/progit2-id",
    "it" => "progit/progit2-it",
    "ja" => "progit/progit2-ja",
    "ko" => "progit/progit2-ko",
    "mk" => "progit2-mk/progit2",
    "ms" => "progit2-ms/progit2",
    "nl" => "progit/progit2-nl",
    "pl" => "progit2-pl/progit2-pl",
    "pt-br" => "progit2-pt-br/progit2",
    "ru" => "progit/progit2-ru",
    "sl" => "progit/progit2-sl",
    "sr" => "progit/progit2-sr",
    "tl" => "progit2-tl/progit2",
    "tr" => "progit/progit2-tr",
    "uk" => "progit/progit2-uk",
    "uz" => "progit/progit2-uz",
    "zh" => "progit/progit2-zh",
    "zh-tw" => "progit/progit2-zh-tw",
    "fa" => "progit2-fa/progit2"
  }

  if ENV['GENLANG']
    books = all_books.select { |code, repo| code == ENV['GENLANG']}
  else
    books = all_books.select do |code, repo|
      repo_head = @octokit.ref(repo, "heads/master").object[:sha]
      book = Book.where(:edition => 2, :code => code).first_or_create
      repo_head != book.ebook_html
    end
  end

  books.each do |code, repo|
    begin
      blob_content = Hash.new do |blobs, sha|
        content = Base64.decode64( @octokit.blob(repo, sha, :encoding => 'base64' ).content )
        blobs[sha] = content.force_encoding('UTF-8')
      end
      repo_tree = @octokit.tree(repo, "HEAD", :recursive => true)
      genbook(code) do |filename|
        file_handle = repo_tree.tree.detect { |tree| tree[:path] == filename }
        if file_handle
          blob_content[file_handle[:sha]]
        end
      end
      repo_head = @octokit.ref(repo, "heads/master").object[:sha]

      book = Book.where(:edition => 2, :code => code).first_or_create
      book.ebook_html = repo_head

      begin
        rel = @octokit.latest_release(repo)
        get_url =   -> content_type do
          asset = rel.assets.select { |asset| asset.content_type==content_type}.first
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

    rescue Exception => msg
      puts msg
    end
  end
end

desc "Generate book html directly from git repo"
task :local_genbook2 => :environment do
  if (ENV['GENLANG'] && ENV['GENPATH'])
    genbook(ENV['GENLANG']) do |filename|
      File.open(File.join(ENV['GENPATH'], filename), "r") {|infile| File.read(infile)}
    end
  end
end

desc "Generate the book html for the sites (by downloading from atlas)"
task :genbook2 => :environment do
  if ENV['GENLANG']
    books = Book.where(:edition => 2, :code => ENV['GENLANG'])
  else
    books = Book.where(:edition => 2, :processed => false)
  end

  nav = '<div id="nav"><a href="[[nav-prev]]">prev</a> | <a href="[[nav-next]]">next</a></div>'

  books.each do |book|
    html_file = download(book.ebook_html) # download processed html ebook
    Zip::File.open(html_file) do |zip_file|
      # Handle entries one by one
      max_chapter = 0

      chapters = {}
      appnumber = 0
      chnumber = 0
      ids = {}

      toc = JSON.parse(zip_file.find_entry("build.json").get_input_stream.read)

      navi = nil
      if toc['navigations']
        navi = toc['navigations']['navigation']
      elsif toc['navigation']
        navi = toc['navigation']['navigation']
      end

      navi.each_with_index do |chthing, index|
        if chthing['type'] == 'appendix'
          appnumber += 1
          chapters["xapp#{index}"] = ['appendix', appnumber, chthing['href'], chthing['label']]
        end
        if chthing['type'] == 'chapter'
          chnumber += 1
          chapters["ch#{index}"] = ['chapter', chnumber, chthing['href'], chthing['label']]
        end
        chthing['children'].each do |child|
          ids[child['id']] = child['label']
        end
      end

      # sort and create the numbers in order
      number = 0
      chapters.sort.each_with_index do |entry, index|
        p entry
        chapter_type, chapter_number, file, title = entry[1]
        p file
        content = zip_file.find_entry(file).get_input_stream.read

        doc = Nokogiri::HTML(content)
        chapter =       doc.at("section[@data-type=#{chapter_type}]")
        chapter_title = title

        next if !chapter_title
        next if !chapter_number

        puts chapter_title
        puts chapter_number
        number = chapter_number
        if chapter_type == 'appendix'
          number = 100 + chapter_number
        end

        id_xref = chapter.attribute('id').to_s
        pretext = "<a id=\"#{id_xref}\"></a>"
        pretext += doc.search("section[@data-type=#{chapter_type}] > p").to_html

        schapter = book.chapters.where(:number => number).first_or_create
        schapter.title = chapter_title.to_s
        schapter.chapter_type = chapter_type
        schapter.chapter_number = chapter_number
        schapter.sha = book.ebook_html
        schapter.save

        # create xref
        csection = schapter.sections.where(:number => 1).first_or_create
        xref = Xref.where(:book_id => book.id, :name => id_xref).first_or_create
        xref.section = csection
        xref.save

        section = 1
        chapter.search("section[@data-type=sect1]").each do |sec|
          id_xref = sec.attribute('id').to_s
          section_title = ids[id_xref]
          pretext += "<a id=\"#{id_xref}\"></a>"
          html = pretext + sec.inner_html.to_s + nav

          html.gsub!('<h3', '<h4')
          html.gsub!(/\/h3>/, '/h4>')
          html.gsub!('<h2', '<h3')
          html.gsub!(/\/h2>/, '/h3>')
          html.gsub!('<h1', '<h2')
          html.gsub!(/\/h1>/, '/h2>')

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

          html.gsub!(%r{&amp;(gt|lt|amp);}, '&\1;')
          html.gsub!(%r{&amp;</code>(<code class="n">)?(gt|lt|amp)(</code>)?<code class=".">;}, '&\2;')

          if subsec = html.scan(/<h3>(.*?)<\/h3>/)
            subsec.each do |sub|
              sub = sub.first
              id = sub.gsub(' ', '-')
              html.gsub!(/<h3>#{sub}<\/h3>/, "<h3 id=\"#{id}\"><a href=\"##{id}\">#{sub}</a></h3>") rescue nil
            end
          end

          if subsec = html.scan(/<img src="(.*?)"/)
            subsec.each do |sub|
              sub = sub.first
              html.gsub!(/<img src="#{sub}"/, "<img src=\"/book/en/v2/#{sub}\"") rescue nil
            end
          end

          puts "\t\t#{chapter_type} #{chapter_number}.#{section} : #{chapter_title} . #{section_title} - #{html.size}"

          csection = schapter.sections.where(:number => section).first_or_create
          csection.title = section_title.to_s
          csection.html = html
          csection.save

          xref = Xref.where(:book_id => book.id, :name => id_xref).first_or_create
          xref.section = csection
          xref.save

          # record all the xrefs
          (sec.search("section[@id]")+sec.search("figure[@id]")+sec.search("table[@id]")).each do |id|
            id_xref = id.attribute('id').to_s
            if id_xref[0,3] != 'idp'
              xref = Xref.where(:book_id => book.id, :name => id_xref).first_or_create
              xref.section = csection
              xref.save
            end
          end

          section += 1
          pretext = ""
        end # loop through sections
        #extra = schapter.sections.where("number >= #{section}")
        #extra.delete_all
      end # if it's a chapter
      #extra = book.chapters.where("number > #{number}")
      #extra.delete_all
    end

    book.processed = true
    book.save

    book.sections.each do |section|
      section.set_slug
      section.save
    end
  end
end


def self.download(url)
  puts "downloading #{url}"
  #return "/Users/schacon/github/progit/gitscm2/ugh/progit-en.661.zip" # for testing
  file = File.new("#{Rails.root}/tmp/download" + Time.now.to_i.to_s + Random.new.rand(100).to_s, 'wb')
  begin
    uri = URI.parse(url)
    Net::HTTP.start(uri.host,uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request_get(uri.path) do |resp|
        resp.read_body do |segment|
          file.write(segment)
        end
      end
    end
    puts "Done."
  ensure
    file.close
  end
  file.path
end

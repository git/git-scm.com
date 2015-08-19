require 'zip'
require 'nokogiri'

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
        pretext += doc.at("section[@data-type=#{chapter_type}] > p").to_html

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

          if xlink = html.scan(/\.html\#(.*?)\"/)
            xlink.each do |link|
              xref = link.first
              html.gsub!(/\.html\##{xref}\"/, "/#{xref}\"") rescue nil
            end
          end

          if xlink = html.scan(/href=\"\#(.*?)\"/)
            xlink.each do |link|
              xref = link.first
              html.gsub!(/href=\"\##{xref}\"/, "href=\"ch00/#{xref}\"") rescue nil
            end
          end

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
          sec.search("section[@id]").each do |id|
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

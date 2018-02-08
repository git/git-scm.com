require 'redcarpet'
require 'octokit'
require 'digest/sha1'

# export GITBOOK_DIR=../../writing/progit/
# bundle exec rake genbook GENLANG=en

SCRIPT_SHA = Digest::SHA1.hexdigest(File.open('lib/tasks/book.rake', 'r').read)

def generate_pages(lang, chapter, content, sha)
  toc = {:title => '', :sections => []}

  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :tables => true)

  content.gsub! /(\n(\n\t([^\t\n]+)\t([^\t\n]+))+\n\n)/ do
    first_col=20
    $1.gsub /(\n?)\n\t([^\t\n]+)\t([^\t\n]+)/ do
      if $1=="\n"
        # This is the header, need to add the dash line
        $1 << "\n " << $2 <<  " "*(first_col-$2.length) + "| " << $3 <<
          "\n " << "-"*first_col << "|-" << "-"*$3.length
      else
        # Table row : format the first column as typewriter and align
        $1 << "\n `" << $2 << "`" + " "*(first_col-$2.length-2) + "| " << $3
      end
    end
  end

  raw = markdown.render(content)

  if m = raw.match(/<h1(.*?)>(.*?)<\/h1>/)
    chapter_title = m[2]
    toc[:title] = chapter_title
  end

  # replace images
  if images = raw.scan(/Insert (.*?).png/)
    images.each do |img|
      img = img.first
      real = "<center><img src=\"/figures/#{img}-tn.png\"></center><br/>"
      raw.gsub!(/Insert #{img}.png/, real)
    end
  end

  # add anchors to h3s
  if subsec = raw.scan(/<h3>(.*?)<\/h3>/)
    subsec.each do |sub|
      sub = sub.first
      id = sub.gsub(' ', '-')
      raw.gsub!(/<h3>#{sub}<\/h3>/, "<h3 id=\"#{id}\"><a href=\"##{id}\">#{sub}</a></h3>")
    end
  end

  # add a class to tables
  raw.gsub! /<table>/, "<table class='ref'>"

  sections = raw.split('<h2')

  section = 0
  # create book (if needed)
  book = Book.where(:edition => 1, :code => lang).first_or_create

  # create chapter (if needed)
  schapter = book.chapters.where(:number => chapter).first_or_create
  schapter.title = chapter_title.to_s
  schapter.sha = sha + SCRIPT_SHA
  schapter.save

  schapter.destroy if sections.empty?

  sections.each do |sec|

    section_title = ''
    if section_match = sec.match(/>(.*?)<\/h2>/)
      section_title = section_match[1]
      toc[:sections] << [section, section_title]
    else
      toc[:sections] << [section, nil]
    end

    full_title = section_match ? "#{chapter_title} #{section_title}" : chapter_title

    html = ''
    if section_match
      sec = '<h2' + sec
    else
      html += "<h1>Chapter #{chapter}</h1>"
    end

    html += sec

    nav = '<div id="nav"><a href="[[nav-prev]]">prev</a> | <a href="[[nav-next]]">next</a></div>'
    html += nav

    # create/update section
    csection = schapter.sections.where(:number => section).first_or_create
    csection.title = section_title.to_s
    csection.html = html.to_s
    csection.save

    puts "\t\t#{chapter}.#{section} : #{chapter_title} . #{section_title} - #{html.size}"

    section += 1
  end
  schapter.sections.where("number >= #{section}").destroy_all
  toc
end

namespace :book do
  desc "Update slug name"
  task :update_slug => :environment do
    Book.includes(:chapters => :sections).all.each do |book|
      book.sections.each do |section|
        section.set_slug
        section.save
      end
    end
  end
end

desc "Generate the book html for the sites (Using Octokit gem)"
task :remote_genbook => :environment do
  @octokit = Octokit::Client.new(:login => ENV['API_USER'], :password => ENV['API_PASS'])
  repo = 'progit/progit'
  book = {}
  blob_content = Hash.new do |blobs, sha|
    content = Base64.decode64( @octokit.blob( repo, sha, :encoding => 'base64' ).content )
    blobs[sha] = content.force_encoding('UTF-8')
  end
  repo_tree = @octokit.tree(repo, "HEAD", :recursive => true)
  trees = repo_tree.tree.map {|tree| tree if tree.path =~ /\.markdown$/}.compact
  trees.each do |tree|
    #tree = trees.first
    lang, section, chapter = tree.path.split("/")
    section_number = $1 if section =~ /^(\d+)/
    chapter_number = $1 if chapter =~ /chapter(\d+)\.markdown/

    skip = false

    if book = Book.where(:edition => 1, :code => lang).first
      c = book.chapters.where(:number => chapter_number.to_i).first
      if c && (c.sha == (tree.sha + SCRIPT_SHA))
        skip = true
      end
    end

    skip = true if chapter_number.to_i == 0
    skip = false if ENV['REGEN_ALL']

    puts "*** #{skip} #{tree.sha}- #{lang} - #{section} - #{chapter} - #{section_number}:#{chapter_number}"

    if !skip
      #book[lang] ||= []
      content = blob_content[tree.sha]
      #book[lang] << {:sha => tree.sha, :section => section, :chapter => chapter, :blob => content}
      generate_pages(lang, chapter_number, content, tree.sha)
    end
  end
  #p book
end

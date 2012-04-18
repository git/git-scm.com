require 'redcarpet'
require 'nestful'
require 'awesome_print'

# export GITBOOK_DIR=../../writing/progit/
# export GITBOOK_DIR=../../writing/progit/

CONTENT_SERVER = ENV["CONTENT_SERVER"] || "http://localhost:3000"

def generate_pages(lang, chapter, content)
  toc = {:title => '', :sections => []}

  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  raw = markdown.render(content)

  if m = raw.match(/<h1(.*?)>(.*?)<\/h1>/)
    chapter_title = m[2]
    toc[:title] = chapter_title
  end

  # replace images
  if images = raw.scan(/Insert (.*?).png/)
    images.each do |img|
      real = "<center><img src=\"/figures/ch#{chapter}/#{img}-tn.png\"></center><br/>"
      raw.gsub!("Insert #{img}.png", real)
    end
  end

  sections = raw.split('<h2')
  section = 0
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

    nav = "<div id='nav'><a href='[[nav-prev]]'>prev</a> | <a href='[[nav-next]]'>next</a></div>"
    html += nav

    data = {
      :lang => lang,
      :chapter => chapter,
      :section => section,
      :chapter_title => chapter_title,
      :section_title => section_title,
      :content => html,
      :token => ENV['UPDATE_TOKEN']
    }

    url = CONTENT_SERVER + "/publish"
    result = Nestful.post url, :format => :form, :params => data
    
    puts "\t\t#{chapter}.#{section} : #{chapter_title} . #{section_title} - #{html.size} (#{result})"

    section += 1
  end
  toc
end

# generate the site
desc "Generate the book html for the site"
task :genbook do
  genlang     = ENV['GENLANG']
  gitbook_dir = ENV['GITBOOK_DIR']

  if !File.exists?(gitbook_dir)
    puts "No such directory"
    exit 
  end

  Dir.chdir(gitbook_dir) do
    Dir.glob("*").each do |lang|
      chapter_number = 0
      toc = []
      next if genlang && genlang != lang
      next if !File.directory? lang
      Dir.chdir(lang) do
        next if !File.exists?('01-introduction') # not a chapter
        puts 'generating : ' + lang
        Dir.glob("*").each do |chapter|
          next if !File.directory? chapter
          content = ''
          begin
            Dir.chdir(chapter) do
              puts "\t" + chapter
              Dir.glob('*').each do |section|
                content += File.read(section)
              end
              chapter_number += 1
              toc << [chapter_number, generate_pages(lang, chapter_number, content)]
            end
          rescue Object => e
            ap e
          end 
        end
      end
    end
  end

end

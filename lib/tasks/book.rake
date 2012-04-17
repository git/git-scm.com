require 'redcarpet'
require 'awesome_print'

# export GITBOOK_DIR=../../writing/progit/

def generate_pages(lang, chapter, content)
  toc = {:title => '', :sections => []}

  doc = Maruku.new(content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(content)

  raw = doc.to_html
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

    if lang == 'en'
      pname = "../../../book/ch#{chapter}-#{section}.html"
    else
      FileUtils.mkdir("../../../book/#{lang}") rescue nil
      pname = "../../../book/#{lang}/ch#{chapter}-#{section}.html"
    end

    full_title = section_match ? "#{chapter_title} #{section_title}" : chapter_title
    layout = lang == 'en' ? 'master' : 'translation'
    html = "---
layout: #{layout}
title: Pro Git #{chapter}.#{section} #{full_title}
---
"
    if section_match
      sec = '<h2' + sec
    else
      html += "<h1>Chapter #{chapter}</h1>"
    end

    html += sec

    nav = "<div id='nav'>
<a href='[[nav-prev]]'>prev</a> | <a href='[[nav-next]]'>next</a>
</div>"
    html += nav

    File.open(pname, 'w+') { |f| f.write(html) }
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

  Dir.chdir(File.join(gitbook_dir, 'translations')) do
    Dir.glob("*").each do |lang|
      chapter_number = 0
      toc = []
      next if genlang && genlang != lang
      Dir.chdir(lang) do
        Dir.glob("*").each do |chapter|
          puts 'generating : ' + lang + '/' + chapter
          content = ''
          Dir.chdir(chapter) do
            Dir.glob('*').each do |section|
              content += File.read(section)
            end
            chapter_number += 1
            toc << [chapter_number, generate_pages(lang, chapter_number, content)]
          end rescue nil
        end
      end
    end
  end

end

# generate the site
desc "Convert images"
task :convert_images do
  Dir.chdir('figures') do
    Dir.glob("*").each do |chapter|
      Dir.chdir(chapter) do
        Dir.glob("*").each do |image|
          puts image
          (im, ending) = image.split('.')
          if ending == 'png' and im[-3, 3] != '-tn'
            convert_image = "#{im}-tn.png"
            if !File.exists?(convert_image)
              width_out = `exiftool #{image} | grep 'Image Width'`
              width = width_out.scan(/: (\d+)/).first.first.to_i
              if width > 500
                `convert -thumbnail 500x #{image} #{convert_image}`
              else
                `cp #{image} #{convert_image}`
              end
            end
          end
        end
      end
    end
  end
end

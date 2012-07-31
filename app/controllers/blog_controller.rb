class BlogController < ApplicationController

  # for progit.org blog
  def progit
    year  = params[:year]
    month = params[:month]
    day   = params[:day]
    slug  = params[:slug]
    file  = "#{year}-#{month}-#{day}-#{slug}"
    @path = "#{Rails.root}/app/views/blog/progit/#{file}"
    content = ''
    if File.exists?("#{@path}.markdown")
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      content = File.read("#{@path}.markdown")
      content, @frontmatter = extract_frontmatter(content)
      @content = markdown.render(content)
    elsif File.exists?("#{path}.html")
      content = File.read("#{path}.html")
      @content, @frontmatter = extract_frontmatter(content)
    else
      raise PageNotFound
    end

  end

  # for Gitscm blog
  def gitscm

  end

  private

  def extract_frontmatter(content)
    if content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)(.*)/m
      cnt = $3
      data = YAML.load($1)
      [cnt, data]
    else
      [content, {}]
    end
  end

end

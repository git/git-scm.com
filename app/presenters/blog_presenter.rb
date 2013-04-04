class BlogPresenter
  
  def initialize(file)
    @file = file
    @path = "#{Rails.root}/app/views/blog/posts/#{@file}"
  end

  def exists?
    File.exists?("#{@path}.markdown") || File.exists?("#{@path}.html")
  end

  def render
    if File.exists?("#{@path}.markdown")
      source = File.read("#{@path}.markdown")
      content, frontmatter = extract_frontmatter(source)
      template = markdown.render(content)
      [template, frontmatter]
    elsif File.exists?("#{@path}.html")
      source = File.read("#{@path}.html")
      extract_frontmatter(source)
    end
  end

  private
  
  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

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

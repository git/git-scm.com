module DocHelper
  def man(name)
    "<a href=\"/doc/ref/#{name}\">#{name.gsub('git-', '')}</a>".html_safe
  end
end

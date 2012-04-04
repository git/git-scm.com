module DocHelper
  def man(name)
    "<a href=\"/ref/#{name}\">#{name.gsub('git-', '')}</a>".html_safe
  end
end

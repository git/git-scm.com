module DocHelper
  def man(name)
    "<a href=\"/docs/#{name}\">#{name.gsub('git-', '')}</a>".html_safe
  end
  def linkify(content, section)
    next_page = section.next_slug
    prev_page = section.prev_slug
    content.gsub('[[nav-next]]', next_page).gsub('[[nav-prev]]', prev_page)
  end
end

module DocHelper

  def man(name, options = {})
    link_to options[:text] || name.gsub(/^git-/, ''), doc_file_path(:file => name), :class => options[:class]
  end

  def linkify(content, section)
    next_page = section.next_slug
    prev_page = section.prev_slug
    content.gsub('[[nav-next]]', next_page).gsub('[[nav-prev]]', prev_page)
  end
end

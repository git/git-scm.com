module DocHelper
  
  def man(name)
    link_to name.gsub('git-', ''), doc_file_path(name)
  end

  def linkify(content, section)
    next_page = section.next_slug
    prev_page = section.prev_slug
    content.gsub('[[nav-next]]', next_page).gsub('[[nav-prev]]', prev_page)
  end

end

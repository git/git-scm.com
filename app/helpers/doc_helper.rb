module DocHelper

  def man(name, text = nil)
    link_to text || name.gsub(/^git-/, ''), doc_file_path(:file => name)
  end

  def linkify(content, section)
    next_page = section.next_slug
    prev_page = section.prev_slug
    content.gsub('[[nav-next]]', next_page).gsub('[[nav-prev]]', prev_page)
  end
end

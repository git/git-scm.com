# frozen_string_literal: true

module DocHelper

<<<<<<< HEAD
  def man(name, text = nil)
    if @language && @language != "en"
      link_to text || name.gsub(/^git-/, ""), doc_file_path(file: name,) +"/#{@language}", class: ("active" if @name == name)
    else
      link_to text || name.gsub(/^git-/, ""), doc_file_path(file: name), class: ("active" if @name == name)
    end
=======
  def man(name, options = {})
    link_to options[:text] || name.gsub(/^git-/, ""), doc_file_path(file: name), class: options[:class]
>>>>>>> origin/v2
  end

  def linkify(content, section)
    next_page = section.next_slug
    prev_page = section.prev_slug
    content.gsub("[[nav-next]]", next_page).gsub("[[nav-prev]]", prev_page)
  end
end

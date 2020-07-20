# frozen_string_literal: true

module BooksHelper

  def same_section(content, section)
    content.number == section.number && content.chapter.cs_number == section.chapter.cs_number
  end

end

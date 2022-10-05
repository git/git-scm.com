# frozen_string_literal: true

# t.string      :title
# t.integer     :number
# t.belongs_to  :book
# t.timestamps
class Chapter < ApplicationRecord
  default_scope { order(:number) }
  belongs_to :book
  has_many :sections, dependent: :delete_all
  has_many :chapters, through: :book

  def prev
    return false unless number

    num = number - 1
    return chapters.find_by(number: num) if num > 0

    false
  end

  def next
    return false unless number

    num = number + 1
    return chapters.find_by(number: num) if num > 0

    false
  end

  def last_section
    sections.reorder("number DESC").first
  end

  def first_section
    sections.first
  end

  def cs_number
    if chapter_type == "appendix"
      "A" + chapter_number
    else
      chapter_number
    end
  end
end

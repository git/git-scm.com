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
    return false unless self.number
    num = self.number - 1
    return self.chapters.find_by(number: num) if num > 0
    false
  end

  def next
    return false unless self.number
    num = self.number + 1
    return self.chapters.find_by(number: num) if num > 0
    false
  end

  def last_section
    self.sections.reorder("number DESC").first
  end

  def first_section
    self.sections.first
  end

  def cs_number
    if self.chapter_type == "appendix"
      "A" + self.chapter_number
    else
      self.chapter_number
    end
  end
end

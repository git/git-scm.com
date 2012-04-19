# t.string      :title
# t.integer     :number
# t.belongs_to  :book
# t.timestamps
class Chapter < ActiveRecord::Base
  default_scope :order => 'number'
  belongs_to :book
  has_many :sections

  def prev
    num = self.number - 1
    return self.book.chapters.where(:number => num).first if num > 0
    false
  end

  def next
    num = self.number + 1
    return self.book.chapters.where(:number => num).first if num > 0
    false
  end

  def last_section
    self.sections.reorder("number DESC").first
  end

  def first_section
    self.sections.first
  end
end

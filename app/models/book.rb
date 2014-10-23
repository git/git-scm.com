# t.string      :code
# t.timestamps
class Book < ActiveRecord::Base
  has_many :chapters
  has_many :sections, :through => :chapters

  def has_edition(number)
    Book.where(:edition => number, :code => self.code).count > 0
  end
end

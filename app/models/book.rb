# t.string      :code
# t.timestamps
class Book < ActiveRecord::Base
  has_many :chapters
  has_many :sections, :through => :chapters
end

# t.string      :code
# t.timestamps
class Book < ActiveRecord::Base
  has_many :chapters
end

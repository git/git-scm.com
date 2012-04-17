# t.string      :title
# t.belongs_to  :book
# t.timestamps
class Chapter < ActiveRecord::Base
  belongs_to :book
  has_many :sections
end

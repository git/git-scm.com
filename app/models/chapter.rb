# t.string      :title
# t.integer     :number
# t.belongs_to  :book
# t.timestamps
class Chapter < ActiveRecord::Base
  default_scope :order => 'number'
  belongs_to :book
  has_many :sections
end

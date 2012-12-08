# t.string :name
# t.integer :commit_count
class Author < ActiveRecord::Base
  validates :name, :uniqueness => true
end

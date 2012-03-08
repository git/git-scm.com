class Version < ActiveRecord::Base
  validates :name, :uniqueness => true

  has_many :doc_versions
  has_many :docs, :through => :doc_versions
end

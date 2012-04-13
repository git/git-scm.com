# t.string :name
# t.string :commit_sha
# t.string :tree_sha
# t.datetime :committed
# t.timestamps
class Version < ActiveRecord::Base
  validates :name, :uniqueness => true

  has_many :doc_versions
  has_many :docs, :through => :doc_versions

  def self.latest_version
    Version.order('versions.name DESC').first
  end
end

# t.string :name
# t.string :commit_sha
# t.string :tree_sha
# t.datetime :committed
# t.timestamps
class Version < ActiveRecord::Base
  validates :name, :uniqueness => true

  has_many :doc_versions
  has_many :docs, :through => :doc_versions
  has_many :downloads

  before_save :save_version_order

  def save_version_order
    self.vorder = Version.version_to_num(self.name)
  end

  def self.latest_version
    Version.order('versions.vorder DESC').limit(1).first
  end

  def self.version_to_num(version)
    version_int = 0.0
    mult = 1000000
    numbers = version.to_s.split('.')
    numbers.each do |x|
      version_int += x.to_f * mult
      mult = mult / 100.0
    end
    version_int
  end

end

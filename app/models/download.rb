# t.string :url
# t.string :filename
# t.string :platform
# t.references :version
# t.timestamps
class Download < ActiveRecord::Base
  belongs_to :version

  def self.latest_for(platform)
    includes(:version).where('platform=?', platform).order('versions.vorder DESC').order('downloads.filename DESC').first
  end
end

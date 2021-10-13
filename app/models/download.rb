# frozen_string_literal: true

# t.string :url
# t.string :filename
# t.string :platform
# t.references :version
# t.timestamp :release_date
# t.timestamps
class Download < ApplicationRecord
  belongs_to :version

  def self.latest_for(platform)
    includes(:version).where("platform=?", platform).order("versions.vorder DESC").order("downloads.release_date DESC").first
  end
end

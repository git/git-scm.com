# frozen_string_literal: true

class AddReleaseDateToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :release_date, :timestamp

    Download.all.each do |d|
      time = d.version.committed # best guess

      if d.platform == "windows" # for Windows, take it from the filename
        d.filename =~ /Git-(.*?)-(.*?)(\d{4})(\d{2})(\d{2})\.exe/
        time = Time.utc($3, $4, $5)
      end

      d.release_date = time
      d.save
    end
  end
end

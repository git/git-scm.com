# frozen_string_literal: true

class AddDownloads < ActiveRecord::Migration[4.2]
  def up
    create_table :downloads do |t|
      t.string :url
      t.string :filename
      t.string :platform
      t.references :version
      t.timestamps
    end
  end

  def down
    drop_table :downloads
  end
end

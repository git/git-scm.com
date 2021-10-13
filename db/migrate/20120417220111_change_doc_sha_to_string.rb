# frozen_string_literal: true

class ChangeDocShaToString < ActiveRecord::Migration[4.2]
  def up
    change_column :docs, :blob_sha, :string
  end

  def down
    change_column :docs, :blob_sha, :text
  end
end

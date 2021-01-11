# frozen_string_literal: true

class CreateVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :versions do |t|
      t.string :name
      t.string :commit_sha
      t.string :tree_sha
      t.datetime :committed
      t.timestamps
    end
    add_index :versions, [:name]
  end
end

# frozen_string_literal: true

class AddIndexToVersions < ActiveRecord::Migration[6.1]
  def change
    remove_index :versions, :name
    add_index :versions, :name, unique: true
  end
end

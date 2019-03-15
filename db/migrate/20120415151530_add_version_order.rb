# frozen_string_literal: true

class AddVersionOrder < ActiveRecord::Migration
  def up
    add_column :versions, :vorder, :float
    Version.all.each do |version|
      version.save
    end
  end

  def down
    remove_column :versions, :vorder
  end
end

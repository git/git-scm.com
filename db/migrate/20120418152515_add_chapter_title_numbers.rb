# frozen_string_literal: true

class AddChapterTitleNumbers < ActiveRecord::Migration
  def up
    add_column :chapters, :number, :integer
    add_column :sections, :number, :integer
  end

  def down
    remove_column :chapters, :number
    remove_column :sections, :number
  end
end

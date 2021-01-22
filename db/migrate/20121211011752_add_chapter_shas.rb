# frozen_string_literal: true

class AddChapterShas < ActiveRecord::Migration[4.2]
  def up
    add_column :chapters, :sha, :string
  end

  def down
    remove_column :chapters, :string
  end
end

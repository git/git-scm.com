class AddChapterType < ActiveRecord::Migration
  def change
    add_column :chapters, :chapter_type, :string
    add_column :chapters, :chapter_number, :string
  end
end

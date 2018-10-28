# frozen_string_literal: true

class AddChapterType < ActiveRecord::Migration
  def change
    add_column :chapters, :chapter_type, :string, default: "chapter"
    add_column :chapters, :chapter_number, :string

    # fill with defaults
    Chapter.all.each do |chapter|
      chapter.chapter_number = chapter.number
      chapter.save
    end
  end
end

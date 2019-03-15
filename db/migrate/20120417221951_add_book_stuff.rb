# frozen_string_literal: true

class AddBookStuff < ActiveRecord::Migration
  def up
    create_table :books do |t|
      t.string      :code
      t.timestamps
    end
    add_index :books, [:code]

    create_table :chapters do |t|
      t.string      :title
      t.belongs_to  :book
      t.timestamps
    end
    add_index :chapters, [:book_id]

    create_table :sections do |t|
      t.string      :title
      t.string      :slug
      t.text        :plain
      t.text        :html
      t.belongs_to  :chapter
      t.timestamps
    end
    add_index :sections, [:slug]
    add_index :sections, [:chapter_id]
  end

  def down
    drop_table :books
    drop_table :chapters
    drop_table :sections
  end
end

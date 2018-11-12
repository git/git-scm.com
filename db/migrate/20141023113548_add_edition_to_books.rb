# frozen_string_literal: true

class AddEditionToBooks < ActiveRecord::Migration
  def change
    add_column :books, :edition, :integer, default: 1
    add_column :books, :ebook_pdf,  :string
    add_column :books, :ebook_epub, :string
    add_column :books, :ebook_mobi, :string
    add_column :books, :ebook_html, :string
  end
end

# frozen_string_literal: true

class CreateDocs < ActiveRecord::Migration[4.2]
  def change
    create_table :docs do |t|
      t.text :blob_sha
      t.text :plain
      t.text :html
      t.timestamps
    end
    add_index :docs, [:blob_sha]
  end
end

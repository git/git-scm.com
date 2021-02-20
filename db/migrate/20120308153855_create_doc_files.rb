# frozen_string_literal: true

class CreateDocFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :doc_files do |t|
      t.string :name
      t.timestamps
    end
    add_index :doc_files, [:name]
  end
end

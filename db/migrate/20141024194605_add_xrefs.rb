# frozen_string_literal: true

class AddXrefs < ActiveRecord::Migration[4.2]
  def change
    create_table :xrefs do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer :section_id
      t.integer :book_id
      t.string  :name
    end
  end
end

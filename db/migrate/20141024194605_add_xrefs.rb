# frozen_string_literal: true

class AddXrefs < ActiveRecord::Migration
  def change
    create_table :xrefs do |t|
      t.integer :section_id
      t.integer :book_id
      t.string  :name
    end
  end
end

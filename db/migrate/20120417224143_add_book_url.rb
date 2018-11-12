# frozen_string_literal: true

class AddBookUrl < ActiveRecord::Migration
  def up
    add_column :sections, :source_url, :string
  end

  def down
    remove_column :sections, :source_url
  end
end

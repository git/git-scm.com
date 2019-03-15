# frozen_string_literal: true

class AddLanguageName < ActiveRecord::Migration
  def change
    add_column :books, :language, :string
  end
end

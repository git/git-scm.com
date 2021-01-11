# frozen_string_literal: true

class AddLanguageName < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :language, :string
  end
end

# frozen_string_literal: true

class AddPercentComplete < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :percent_complete, :integer
  end
end

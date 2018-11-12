# frozen_string_literal: true

class AddPercentComplete < ActiveRecord::Migration
  def change
    add_column :books, :percent_complete, :integer
  end
end

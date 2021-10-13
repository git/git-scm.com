# frozen_string_literal: true

class AddProcessedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :books, :processed, :boolean
  end
end

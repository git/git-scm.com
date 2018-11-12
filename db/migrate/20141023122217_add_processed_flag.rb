# frozen_string_literal: true

class AddProcessedFlag < ActiveRecord::Migration
  def change
    add_column :books, :processed, :boolean
  end
end

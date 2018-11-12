# frozen_string_literal: true

class CreateDocVersions < ActiveRecord::Migration
  def change
    create_table :doc_versions do |t|
      t.belongs_to :version
      t.belongs_to :doc
      t.belongs_to :doc_file
      t.timestamps
    end
  end
end

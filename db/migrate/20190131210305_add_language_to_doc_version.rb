# frozen_string_literal: true
class AddLanguageToDocVersion < ActiveRecord::Migration
  def change
    add_column :doc_versions, :language, :string, default: "en"
  end
end

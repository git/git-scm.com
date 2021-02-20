# frozen_string_literal: true
class AddLanguageToDocVersion < ActiveRecord::Migration[4.2]
  def change
    add_column :doc_versions, :language, :string, default: "en"
  end
end

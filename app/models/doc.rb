# frozen_string_literal: true

require "pp"
require "searchable"
require "diffy"

# t.text :blob_sha
# t.text :plain
# t.text :html
# t.timestamps
class Doc < ApplicationRecord

  include Searchable

  has_many :doc_versions, dependent: :delete_all

end

# frozen_string_literal: true

require "diff/lcs"
require "pp"
require "searchable"

# t.text :blob_sha
# t.text :plain
# t.text :html
# t.timestamps
class Doc < ApplicationRecord

  include Searchable

  has_many :doc_versions

end

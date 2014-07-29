require 'diff/lcs'
require 'pp'
require 'searchable'

# t.text :blob_sha
# t.text :plain
# t.text :html
# t.timestamps
class Doc < ActiveRecord::Base
  
  include Searchable

  has_many :doc_versions

end

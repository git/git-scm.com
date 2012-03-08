class DocFile < ActiveRecord::Base
  has_many :doc_versions
end

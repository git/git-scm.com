class DocVersion < ActiveRecord::Base
  belongs_to :doc
  belongs_to :version
  belongs_to :doc_file
end

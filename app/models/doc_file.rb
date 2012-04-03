# t.string :name
# t.timestamps
class DocFile < ActiveRecord::Base
  has_many :doc_versions

  # TODO: parse file for description
  def description
    ''
  end
end

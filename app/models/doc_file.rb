# t.string :name
# t.timestamps
class DocFile < ActiveRecord::Base
  has_many :doc_versions
  has_many :versions, through: :doc_versions

  scope :with_includes, ->{ includes(:doc_versions => [:doc, :version]) }

  # TODO: parse file for description
  def description
    ''
  end
end

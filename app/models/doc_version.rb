# frozen_string_literal: true

# t.belongs_to :version
# t.belongs_to :doc
# t.belongs_to :doc_file
# t.timestamps
# t.language
class DocVersion < ApplicationRecord
  belongs_to :doc
  belongs_to :version
  belongs_to :doc_file

  scope :with_includes, -> { includes(:doc) }
  scope :for_version, ->(version) { where(language: "en").joins(:version).where(versions: {name: version}).limit(1).first }
  scope :latest_version, ->(lang = "en") {  where(language: lang).joins(:version).order("versions.vorder DESC").limit(1).first }
  scope :version_changes, -> {  where(language: "en").with_includes.joins(:version).order("versions.vorder DESC") }

  delegate :name, to: :version
  delegate :committed, to: :version

  def index
    file  = self.doc_file
    doc   = self.doc
    client = ElasticClient.instance

    begin
      client.index index: ELASTIC_SEARCH_INDEX,
                   type: "man_doc",
                   id: file.name,
                   body: {
                       name: file.name,
                       blob_sha: doc.blob_sha,
                       text: doc.plain
                   }
    rescue StandardError
      nil
    end
  end

end

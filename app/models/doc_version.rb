# t.belongs_to :version
# t.belongs_to :doc
# t.belongs_to :doc_file
# t.timestamps
class DocVersion < ActiveRecord::Base
  belongs_to :doc
  belongs_to :version
  belongs_to :doc_file

  def self.latest_for(doc_name)
    for_doc(doc_name).joins(:version).order('versions.vorder DESC').first
  end

  def self.last_changed(doc_name)
    version = for_doc(doc_name).joins(:version).order('versions.vorder DESC').first
    sha = version.doc.blob_sha
    for_doc(doc_name).joins(:version).where('docs.blob_sha = ?', sha).order('versions.vorder').first
  end

  def self.latest_versions(doc_name)
    for_doc(doc_name).joins(:version).order('versions.vorder DESC').limit(15)
  end

  def self.for_version(doc_name, version_name)
    for_doc(doc_name).joins(:version).where(['versions.name=?', version_name]).first
  end

  def index
    if BONSAI
      file = self.doc_file
      doc = self.doc
      data = {
        'name' => file.name,
        'blob_sha' => doc.blob_sha,
        'text' => doc.plain,
      }
      BONSAI.add 'doc', file.name, data
    end
  end

  private

    def self.for_doc(doc_name)
      includes(:doc).joins(:doc_file).where('doc_files.name=?', doc_name)
    end

end

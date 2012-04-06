class DocVersion < ActiveRecord::Base
  belongs_to :doc
  belongs_to :version
  belongs_to :doc_file

  def self.latest_for(doc_name)
    for_doc(doc_name).joins(:version).order('versions.id DESC').first
  end

  def self.for_version(doc_name, version_name)
    for_doc(doc_name).joins(:version).where(['versions.name=?', version_name]).first
  end

  def index
    file = self.doc_file
    doc = self.doc
    data = {
      'name' => file.name,
      'blob_sha' => doc.blob_sha,
      'text' => doc.plain,
    }
    BONSAI.add 'doc', file.name, data
  end

  private

    def self.for_doc(doc_name)
      includes(:doc).joins(:doc_file).where('doc_files.name=?', doc_name)
    end

end

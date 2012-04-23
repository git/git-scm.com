# t.belongs_to :version
# t.belongs_to :doc
# t.belongs_to :doc_file
# t.timestamps
class DocVersion < ActiveRecord::Base
  belongs_to :doc
  belongs_to :version
  belongs_to :doc_file

  def self.get_related(doc_name, limit = 10)
    ri = RelatedItem.where(:related_type => 'reference', :related_id => doc_name).order('score DESC').limit(limit)
    ri.sort { |a, b| a.content_type <=> b.content_type }
  end

  def self.latest_for(doc_name)
    for_doc(doc_name).joins(:version).order('versions.vorder DESC').first
  end

  def self.last_changed(doc_name)
    version = for_doc(doc_name).joins(:version).order('versions.vorder DESC').first
    sha = version.doc.blob_sha
    for_doc(doc_name).joins(:version).where('docs.blob_sha = ?', sha).order('versions.vorder').first
  end

  def self.latest_versions(doc_name)
    for_doc(doc_name).joins(:version).order('versions.vorder DESC')
  end

  def self.for_version(doc_name, version_name)
    for_doc(doc_name).joins(:version).where(['versions.name=?', version_name]).first
  end

  def self.version_changes(file, size = 20)
    versions = []
    unchanged = []
    vers = DocVersion.latest_versions(file)
    for i in 0..(vers.size-2)
      v = vers[i]
      prev = vers[i+1]
      sha2 = v.doc.blob_sha
      sha1 = prev.doc.blob_sha
      if sha1 == sha2
        unchanged << v.version.name
      else
        if unchanged.size > 0
          if unchanged.size == 1
            versions << {:name => "#{unchanged.first} no changes", :changed => false}
          else
            versions << {:name => "#{unchanged.last} &rarr; #{unchanged.first} no changes", :changed => false}
          end
          unchanged = []
        end
        versions << {:name => v.version.name, :time => v.version.committed, :diff => Doc.get_diff(sha2, sha1), :changed => true}
      end
    end
    versions[0,size]
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

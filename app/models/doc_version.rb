# t.belongs_to :version
# t.belongs_to :doc
# t.belongs_to :doc_file
# t.timestamps
class DocVersion < ActiveRecord::Base
  belongs_to :doc
  belongs_to :version
  belongs_to :doc_file
  
  scope :with_includes, -> { includes(:doc) }
  scope :for_version, ->(version){ joins(:version).where(versions: {name: version}).limit(1).first }
  scope :latest_version, ->{ joins(:version).order("versions.vorder DESC").limit(1).first }
  
  def self.get_related(doc_name, limit = 10)
    ri = RelatedItem.where(related_type: 'reference', related_id: doc_name).order('score DESC').limit(limit)
    ri.sort_by(&:content_type)
  end

  def self.version_changes(file, size = 20)
    versions = []
    unchanged = []
    vers = includes(:doc, :version).joins(:doc_file).where(doc_files: {name: file}).order("versions.vorder DESC").limit(100)
    (vers.size-2).times do |i|
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
        versions << {:name => v.version.name, :time => v.version.committed, :diff => v.diff(prev), :changed => true}
      end
    end
    versions
  end

  # returns an array of the differences with 3 entries
  # 0: additions
  # 1: subtractions
  # 2: 8 - (add + sub)
  def diff(doc_version)
    begin
      to = self.doc.plain.split("\n")
      from = doc_version.doc.plain.split("\n")
      total = adds = mins = 0
      diff = Diff::LCS.diff(to, from)
      diff.first.each do |change|
        adds += 1 if change.action == "+"
        mins += 1 if change.action == "-"
        total += 1 
      end
      if total > 8
        min = (8.0 / total)
        adds = (adds * min).floor
        mins = (mins * min).floor
      end
      [adds, mins, (8 - total)]
    rescue
      [0, 0, 8]
    end 
  end

  def index
    file  = self.doc_file
    doc   = self.doc
    data = {
      'id'        => file.name,
      'type'      => 'doc',
      'name'      => file.name,
      'blob_sha'  => doc.blob_sha,
      'text'      => doc.plain,
    }
    begin
      Tire.index ELASTIC_SEARCH_INDEX do
        store data
      end
    rescue Exception => e
      nil
    end
  end

end

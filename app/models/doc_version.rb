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
  scope :version_changes, ->{ with_includes.joins(:version).order("versions.vorder DESC") }
  
  delegate :name, to: :version
  delegate :committed, to: :version

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

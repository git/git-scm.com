require 'diff/lcs'
require 'pp'

# t.text :blob_sha
# t.text :plain
# t.text :html
# t.timestamps
class Doc < ActiveRecord::Base
  has_many :doc_versions

  def self.search(term, highlight = false)
    query_options = {
      "bool" => {
        "should" => [
            { "prefix" => { "name" => { "value" => term, "boost" => 12.0 } } },
            { "term" => { "text" => term } }
        ],
        "minimum_number_should_match" => 1
      }
    }

    highlight_options = {
      'pre_tags'  => ['[highlight]'],
      'post_tags' => ['[xhighlight]'],
      'fields'    => { 'text' => {"fragment_size" => 200} }
    }

    options = { 'query' => query_options,
                'size' => 10 }
    options['highlight'] = highlight_options

    resp  = BONSAI.search('doc', options)

    ref_hits = []
    resp['hits']['hits'].each do |hit|
      highlight = hit.has_key?('highlight') ? hit['highlight']['text'].first : nil
      name = hit["_source"]["name"]
      ref_hits << { 
        :name => name,
        :score => hit["_score"],
        :highlight => highlight,
        :url  => "/docs/#{name}"
      }
    end

    if ref_hits.size > 0
      return { :category => "Reference", :term => term, :matches  => ref_hits }
    else
      nil
    end
  end

  # returns an array of the differences with 3 entries
  # 0: additions
  # 1: subtractions
  # 2: 8 - (add + sub)
  def self.get_diff(sha_to, sha_from)
    key = "diff-#{sha_to}-#{sha_from}"
    Rails.cache.fetch(key) do
      doc_to = Doc.where(:blob_sha => sha_to).first.plain.split("\n")
      doc_from = Doc.where(:blob_sha => sha_from).first.plain.split("\n")
      diff = Diff::LCS.diff(doc_to, doc_from)
      total = adds = mins = 0
      diff.first.each do |change|
        adds += 1 if change.action == '+'
        mins += 1 if change.action == '-'
        total += 1
      end
      if total > 8
        min = (8.0 / total)
        adds = (adds * min).floor
        mins = (mins * min).floor
        [adds, mins, (8 - total)]
      else
        [adds, mins, (8 - total)]
      end
    end
  rescue
    [0, 0, 8]
  end
end

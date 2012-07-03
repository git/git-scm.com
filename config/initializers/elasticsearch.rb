require 'elasticsearch'

if ENV['SEARCH_INDEX_URL']
  ELASTICSEARCH = {
    url:        ENV['SEARCH_INDEX_URL'],
    index_name: 'gitscm'
  }
  BONSAI = ElasticSearch::Index.new ELASTICSEARCH[:index_name], ELASTICSEARCH[:url]
end

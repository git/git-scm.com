require 'elasticsearch'

if ENV['SEARCH_INDEX_URL']
  uri = URI.parse(ENV['SEARCH_INDEX_URL'])
  ELASTICSEARCH = {
    url:        "#{uri.scheme}://#{uri.host}",
    index_name: 'gitscm'
  }
  BONSAI = ElasticSearch::Index.new ELASTICSEARCH[:index_name], ELASTICSEARCH[:url]
end

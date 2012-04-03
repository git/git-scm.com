require 'elasticsearch'

if ENV['BONSAI_INDEX_URL']
  uri = URI.parse(ENV['BONSAI_INDEX_URL'])
  ELASTICSEARCH = {
    url:        "#{uri.scheme}://#{uri.host}",
    index_name: uri.path.gsub('/', '')
  }
  BONSAI = ElasticSearch::Index.new ELASTICSEARCH[:index_name], ELASTICSEARCH[:url]
end

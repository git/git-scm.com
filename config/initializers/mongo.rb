require 'uri'
require 'mongo'

if Rails.env == 'production'
  uri  = URI.parse(ENV['MONGOLAB_URI'])
  conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  db   = conn.db(uri.path.gsub(/^\//, ''))
  Rails.configuration.mongo_db = db
else
  Rails.configuration.mongo_db = Mongo::Connection.new["gitscm-library-#{Rails.env}"]
end

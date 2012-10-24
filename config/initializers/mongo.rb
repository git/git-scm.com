if Rails.env == 'production'
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  Rails.configuration.mongo_db = db_connection
else
  Rails.configuration.mongo_db = Mongo::Connection.new["gitscm-library-#{Rails.env}"]
end

Rails.configuration.mongo_db = Mongo::Connection.new["gitscm-library-#{Rails.env}"]

Tire.configure do
  url (ENV["SEARCH_INDEX_URL"] || "http://0.0.0.0:9200")
end

ELASTIC_SEARCH_INDEX = "gitscm"

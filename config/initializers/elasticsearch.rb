Tire.configure do
  url (ENV["BONSAI_URL"] || "http://0.0.0.0:9200")
end

ELASTIC_SEARCH_INDEX = "gitscm"

# frozen_string_literal: true

class ElasticClient

  @@instance = Elasticsearch::Client.new url: (ENV["BONSAI_URL"] || "http://0.0.0.0:9200"), log: false

  def self.instance
    return @@instance
  end

  private_class_method :new
end


ELASTIC_SEARCH_INDEX = "gitscm"

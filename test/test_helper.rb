# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

Faraday.new(url: "http://0.0.0.0:9200") do |builder|
  builder.request :json
  builder.adapter :test do |stub|
    resp = {
      "hits" => {"hits" => []}
    }
    stub.get("/gitscm/doc/_search") { [200, {}, JSON.dump(resp)] }
    stub.get("/gitscm/book/_search") { [200, {}, JSON.dump(resp)] }
    stub.put("/gitscm/book/en---Title-1-Title-2") { [200, {}, "{}"] }
  end
end

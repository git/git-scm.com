# frozen_string_literal: true
require "octokit"
require "typhoeus/adapters/faraday"

Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.use FaradayMiddleware::Gzip
  builder.use :instrumentation
  builder.request :retry
  builder.adapter :typhoeus
end

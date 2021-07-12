# frozen_string_literal: true

source "https://rubygems.org"
ruby "2.7.3"

gem "rails", "~> 6.0"

gem "asciidoctor", "~> 2.0.0"
gem "elasticsearch", "2.0.2"
gem "faraday"
gem "faraday_middleware"
gem "iso8601"
gem "octokit"
gem "puma"

gem "diffy"
gem "nokogiri"
gem "yajl-ruby"

# Assets
gem "listen"
gem "sass-rails"
gem "uglifier"

group :development do
  gem "awesome_print"
  gem "better_errors"
  gem "binding_of_caller"
  gem "foreman"
end

group :development, :test do
  gem "dotenv-rails"
  gem "pry-byebug"
  gem "rubocop-github"
  gem "ruby-prof"
  gem "sqlite3"
end

group :test do
  gem "database_cleaner"
  gem "fabrication"
  gem "factory_bot_rails"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "shoulda"
  gem "vcr"
  gem "webmock"
end

group :production do
  gem "pg"
  gem "rack-timeout"
  gem "rails_12factor"
  gem "redis-rails"
end

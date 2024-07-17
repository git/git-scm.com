# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.1.3"

gem "rails", "~> 6.0"

# hacks for rails6 + ruby 3.1
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

gem "asciidoctor", "~> 2.0.0"
gem "elasticsearch", "2.0.2"
gem "iso8601"
gem "octokit"
gem "puma"

gem "diffy"
gem "nokogiri"
gem "rss", ">= 0.3.0"

# Assets
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
  gem "listen"
  gem "pry-byebug"
  gem "rubocop", ">= 1.37.0"
  gem "rubocop-discourse", ">= 3.0.1"
  gem "rubocop-performance", ">= 1.11.1"
  gem "rubocop-rails", ">= 2.17.0"
  gem "rubocop-rspec", ">= 2.14.0"
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
  gem "webmock", ">= 3.15.1"
end

group :production do
  gem "pg"
  gem "rack-timeout"
  gem "rails_12factor"
  gem "redis-rails"
end

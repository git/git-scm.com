source 'https://rubygems.org'
ruby "2.4.2"

gem 'rails', '4.2.10'

gem 'asciidoctor', '>=1.5.4'
gem 'faraday'
gem 'faraday_middleware'
gem 'octokit'
gem 'puma'
gem 'tilt'
gem 'tire'
gem 'iso8601'

gem 'json'
gem 'yajl-ruby'
gem 'netrc'
gem 'launchy'
gem 'rubyzip'
gem 'diff-lcs'
gem 'redcarpet'
gem 'nokogiri'

# Assets
gem 'compass-rails'
gem 'sass-rails', '4.0.3'
gem 'uglifier', '3.2.0'

group :development do
  gem "awesome_print"
  gem "better_errors"
  gem "binding_of_caller"
  gem "foreman"
end

group :development, :test do
  gem 'dotenv-rails'
  gem "sqlite3"
  gem 'pry-byebug'
  gem 'ruby-prof'
  gem 'bullet'
end

group :test do
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'webmock'
  gem 'vcr'
  gem 'rails-perftest'
end

group :production do
  gem 'pg', '0.21.0'
  gem 'rack-timeout'
  gem 'rails_12factor'
  gem 'redis-rails'
end

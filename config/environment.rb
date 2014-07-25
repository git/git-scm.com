# Load the Rails application.
require File.expand_path('../application', __FILE__)

begin
  Dotenv.load
rescue
end

# Initialize the Rails application.
Rails.application.initialize!

# This file is used by Rack-based servers to start the application.
# frozen_string_literal: true

require_relative "config/environment"

run Rails.application
Rails.application.load_server

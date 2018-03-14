# frozen_string_literal: true

Rack::Timeout.timeout = 20 if Rails.env.production?

# frozen_string_literal: true

Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout,
                                                  service_timeout: 20 if Rails.env.production?

# frozen_string_literal: true

VCR.configure do |c|
  c.configure_rspec_metadata!
  c.cassette_library_dir = "spec/fixtures/cassettes"

  c.default_cassette_options = {
    serialize_with: :json,
    preserve_exact_body_bytes:  true,
    decode_compressed_response: true,
    record: ENV["TRAVIS"] ? :none : :once
  }

  c.before_record { |i| i.request.headers.delete "Authorization" }

  c.hook_into :webmock
end

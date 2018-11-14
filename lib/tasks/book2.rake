# frozen_string_literal: true

require_relative "../downloaders/books/second_edition.rb"

desc "Reset book html to trigger re-build"
task reset_book2: :environment do
  Book.where(edition: 2).each do |book|
    book.ebook_html = "0000000000000000000000000000000000000000"
    book.save
  end
end

desc "Generate book html directly from git repo on GitHub"
task remote_genbook2: :environment do
  Rails.logger = Logger.new(STDOUT)

  # Let us use VCR to save on HTTP requests if we're not in production
  # and the user hasn't opted out.
  use_vcr = !Rails.env.production? && !ENV.fetch("SKIP_VCR", false)

  if (code = ENV.fetch("GENLANG", nil))
    generate_for(code, with_vcr: use_vcr)
  else
    # In local development we are using SQLite3 which doesn't handle multithreaded writes well.
    group_size = Rails.env.production? ? (ApplicationRecord.connection.pool.size - 1) : 1

    Downloaders::Books::SecondEdition::TRANSLATIONS.keys.in_groups_of(group_size) do |codes|
      threads = codes.compact.map do |c|
        Thread.new do
          generate_for(c, with_vcr: use_vcr)
        end
      end

      threads.each { |thread| thread.join }
    end
  end
end

desc "Generate book html directly from git repo on your local machine"
task local_genbook2: :environment do
  if (ENV["GENLANG"] && ENV["GENPATH"])
    genbook(ENV["GENLANG"]) do |filename|
      File.open(File.join(ENV["GENPATH"], filename), "r") { |infile| File.read(infile) }
    end
  end
end

private def generate_for(code, with_vcr:)
  return Downloaders::Books::SecondEdition.generate_for(code) unless with_vcr

  require "vcr"

  VCR.configure do |c|
    c.cassette_library_dir = "spec/fixtures/cassettes/books/second_edition"

    c.default_cassette_options = {
      preserve_exact_body_bytes:  true,
      decode_compressed_response: true,
    }

    c.before_record { |i| i.request.headers.delete "Authorization" }

    c.hook_into :typhoeus
  end

  VCR.use_cassette(code) do
    Downloaders::Books::SecondEdition.generate_for(code)
  end
end

# frozen_string_literal: true

require "test_helper"
require "rails/performance_test_help"
require "database_cleaner"
class BrowsingDocTest < ActionDispatch::PerformanceTest
  self.profile_options = {runs: 10, metrics: [:wall_time, :process_time]}

  def setup
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
    100.times do |i|
      tree_sha    = SecureRandom.hex
      commit_sha  = SecureRandom.hex
      ascii_sha   = SecureRandom.hex
      version = Version.create(name: "#{i}.0.0", commit_sha: commit_sha, tree_sha: tree_sha, committed: Time.current)
      doc_file = DocFile.create(name: "git-config")
      doc = Doc.create(blob_sha: ascii_sha, html: "test", plain: "test")
      doc_version = DocVersion.create(version_id: version.id, doc_id: doc.id, doc_file_id: doc_file.id)
    end
  end

  def teardown
    DatabaseCleaner.clean
  end

  test "browsing git-config" do
    get "/docs/git-config"
  end

end

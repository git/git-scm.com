# frozen_string_literal: true

require File.expand_path("../../test_helper", __FILE__)

class DocVersionTest < ActiveSupport::TestCase

  should belong_to :doc
  should belong_to :version
  should belong_to :doc_file

  test "finds most recent version" do
    range = 0..3
    file = FactoryGirl.create(:doc_file, name: "test-command")
    docs = range.map { |i| FactoryGirl.create(:doc, plain: "Doc #{i}") }
    vers = range.map { |i| FactoryGirl.create(:version, name: "#{i}.0", vorder: Version.version_to_num("#{i}.0")) }
    dver = range.map { |i| FactoryGirl.create(:doc_version, doc_file: file, version: vers[i], doc: docs[i]) }

    dv = DocVersion.latest_for("test-command")
    assert_equal docs[3], dv.doc
  end

  test "finds a specific version" do
    range = 0..3
    file = FactoryGirl.create(:doc_file, name: "test-command")
    docs = range.map { |i| FactoryGirl.create(:doc, plain: "Doc #{i}") }
    vers = range.map { |i| FactoryGirl.create(:version, name: "v#{i}.0") }
    dver = range.map { |i| FactoryGirl.create(:doc_version, doc_file: file, version: vers[i], doc: docs[i]) }

    dv = DocVersion.for_version("test-command", "v2.0")
    assert_equal docs[2], dv.doc
  end

end

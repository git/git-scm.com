# frozen_string_literal: true

require "test_helper"

class VersionTest < ActiveSupport::TestCase

  should have_many :doc_versions
  should have_many(:docs).through(:doc_versions)
  should have_many :downloads

  should validate_uniqueness_of :name

  test "version ordering" do
    v1 = Version.version_to_num("1.0.0")
    v2 = Version.version_to_num("1.7.10")
    v3 = Version.version_to_num("1.8.0.1")
    assert (v1 < v2)
    assert (v2 < v3)
  end

end

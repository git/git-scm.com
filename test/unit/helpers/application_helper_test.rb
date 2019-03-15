# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase

  test "shows random tagline" do
    tagline = random_tagline
    assert tagline =~ /^<em>--<\/em>/
  end

  test "gets the latest version" do
    version = latest_version
    assert_equal "MyString", version
  end

  test "gets the latest release date" do
    date = latest_release_date
    assert_equal "(2012-03-08)", date
  end

  test "shows the latest release note url" do
    url = latest_relnote_url
    assert_equal "https://raw.github.com/git/git/master/Documentation/RelNotes/MyString.txt", url
  end

end

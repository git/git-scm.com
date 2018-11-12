# frozen_string_literal: true

require "test_helper"

class DocHelperTest < ActionView::TestCase

  test "should generate man link" do
    src = man("git-rebase")
    assert_equal '<a href="/docs/git-rebase">rebase</a>', src
  end

end

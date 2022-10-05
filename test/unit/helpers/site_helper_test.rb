# frozen_string_literal: true

require "test_helper"

class SiteHelperTest < ActionView::TestCase

  test "should convert highlight markup into html" do
    src = highlight_no_html("[highlight]hello[xhighlight]")
    expected = tag.span("hello", class: "highlight")
    assert_equal expected, src
  end

end

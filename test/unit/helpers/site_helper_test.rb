# frozen_string_literal: true

require "test_helper"

class SiteHelperTest < ActionView::TestCase

  test "should convert highlight markup into html" do
    src = highlight_no_html("[highlight]hello[xhighlight]")
    expected = content_tag(:span, "hello", class: "highlight")
    assert_equal expected, src
  end

  test "should create rchart" do
    src = rchart("git", [[0, 1], [0, 1]])
    assert_equal "<tr><td nowrap>git</td><td class='desc'></td><td class='number'> 1.00</td><td class='number'> 1.00</td><td class='number'>1x</td></tr>", src
  end

  test "should create trchart" do
    src = trchart("git", [[0, 1], [0, 1], [0, 1]])
    assert_equal "<tr><td nowrap>git</td><td class='desc'></td><td class='number'>  1.0</td><td class='number'>  1.0</td><td class='number'>  1.0</td></tr>", src
  end

  test "should create gchart" do
    src = gchart("git", [[0, 1], [0, 1]])
    assert_equal "<img src=\"https://chart.googleapis.com/chart?chxt=x&amp;cht=bvs&amp;chl=0|0&amp;chd=t:1,1&amp;chds=0,1&amp;chs=100x125&amp;chco=E09FA0|E05F49&amp;chf=bg,s,fcfcfa&chtt=git\" alt=\"init benchmarks\" />", src
  end

end

require 'test_helper'

class BlogPresenterTest < ActiveSupport::TestCase

  setup do
    @good   = ["2010", "08", "25", "notes"] * "-"
    @bad    = ["2015", "01", "01", "failing-test"] * "-"
  end

  test "file should be existed" do
    blog = BlogPresenter.new(@good)
    assert_equal blog.exists?, true
  end

  test "file should not be existed" do
    blog  = BlogPresenter.new(@bad)
    assert_equal blog.exists?, false
  end

  test "file should have content" do
    blog = BlogPresenter.new(@good)
    assert_not_nil blog.render
  end

  test "file should have no content" do
    blog = BlogPresenter.new(@bad)
    assert_nil blog.render
  end

end

require 'test_helper'

class BlogControllerTest < ActionController::TestCase
  
  test "gets the blog index page" do
    get :index
    assert_response :success
  end

  test "gets the blog page" do
    get :post, :year => 2009, :month => '02', :day => 11, :slug => "moved-to-github-pages"
    assert_response :success
  end

end

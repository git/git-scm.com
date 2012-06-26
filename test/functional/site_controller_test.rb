require 'test_helper'

class SiteControllerTest < ActionController::TestCase

  test "should get index" do
    get :index
    assert_response :success
  end

  test "whygitisbetterthanx.com should redirect to about page" do
    get :redirect_wgibtx
    assert_redirected_to about_path
  end

  test "if no slug then should redirect to the book page" do
    get :redirect_combook
    assert_redirected_to book_path
  end

  test "should redirect to particular book page" do
    @request.env['PATH_INFO'] = "/5_submodules.html"
    get :redirect_combook
    assert_redirected_to "http://git-scm.com/book/en/Git-Tools-Submodules"
  end

  test "should redirect to the book page" do
    get :redirect_book
    assert_redirected_to book_path
  end

  test "should redirect to any book page" do
    @request.env['PATH_INFO'] = "/en/Git-Tools-Submodules"
    get :redirect_book
    assert_redirected_to "http://git-scm.com/en/Git-Tools-Submodules"
  end

  test "should get search page" do
    get :search, :search => "git-rebase"
    assert_response :success
  end

  test "should get some search results" do
    get :search_results, :search => "git-rebase"
    assert_response :success
  end

end

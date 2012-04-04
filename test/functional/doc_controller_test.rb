require File.expand_path("../../test_helper", __FILE__)

class DocControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get file" do
    get :file
    assert_response :success
  end

  test "gets the latest version of a man page" do
    get :man, :file => 'test-command'
    assert_response :success
  end

  test "gets a specific version of a man page" do
    get :man, :file => 'test-command', :version => 'v1.0'
    assert_response :success
  end
end

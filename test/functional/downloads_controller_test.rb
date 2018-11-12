# frozen_string_literal: true

require "test_helper"

class DownloadsControllerTest < ActionController::TestCase

  test "should get index page" do
    get :index
    assert_response :success
  end

  test "should get latest page" do
    get :latest
    assert_response :success
  end

  test "should get guis page" do
    get :guis
    assert_response :success
  end

  test "should get gui page" do
    get :gui, platform: "mac"
    assert_response :success
  end

  test "should get download page" do
    get :download, platform: "linux"
    assert_response :success
  end

  test "should redirect back to download page" do
    get :download, platform: "test"
    assert_redirected_to downloads_path
  end

end

# frozen_string_literal: true

require File.expand_path("../../test_helper", __FILE__)

class DocControllerTest < ActionController::TestCase

  test "should get index" do
    book = FactoryBot.create(:book, code: "en")
    get :index
    assert_response :success
  end

  test "gets the latest version of a man page" do
    file = FactoryBot.create(:doc_file, name: "test-command")
    doc  = FactoryBot.create(:doc, plain: "Doc 1", blob_sha: "d670460b4b4aece5915caf5c68d12f560a9fe3e4")
    vers = FactoryBot.create(:version, name: "v1.0", vorder: Version.version_to_num("1.0"))
    dver = FactoryBot.create(:doc_version, doc_file: file, version: vers, doc: doc)
    get :man, params: { file: "test-command" }
    assert_response :success
  end

  test "gets a specific version of a man page" do
    file = FactoryBot.create(:doc_file, name: "test-command")
    doc  = FactoryBot.create(:doc, plain: "Doc 1", blob_sha: "d670460b4b4aece5915caf5c68d12f560a9fe3e4")
    vers = FactoryBot.create(:version, name: "v1.0", vorder: Version.version_to_num("1.0"))
    dver = FactoryBot.create(:doc_version, doc_file: file, version: vers, doc: doc)
    get :man, params: { file: "test-command", version: "v1.0" }
    assert_response :success
  end

  test "tries to prepend 'git-' to find a command" do
    file = FactoryBot.create(:doc_file, name: "git-commit")
    doc  = FactoryBot.create(:doc, plain: "Doc 1")
    vers = FactoryBot.create(:version, name: "v1.0")
    dver = FactoryBot.create(:doc_version, doc_file: file, version: vers, doc: doc)
    get :man, params: { file: "commit", version: "v1.0" }
    assert_redirected_to "/docs/git-commit"
  end

  test "gets the reference page" do
    get :ref
    assert_response :success
  end

  test "gets the videos page" do
    get :videos
    assert_response :success
  end

  test "should redirect to videos page" do
    get :watch, params: { id: "bad-slug" }
    assert_redirected_to videos_path
  end

  test "watches the video" do
    get :watch, params: { id: "get-going" }
    assert_response :success
  end

  test "gets the external links page" do
    get :ext
    assert_response :success
  end
end

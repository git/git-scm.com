require 'test_helper'

class BooksControllerTest < ActionController::TestCase
  test "gets the book page" do
    book = FactoryGirl.create(:book, :code =>'en')
    get :show, :lang => 'en'
    assert_response :success
  end

  test "gets the book section page" do
  end

  test "gets the progit page" do
    section = FactoryGirl.create(:section)
    get :chapter, :chapter => section.chapter.number, :section => section.number
    assert_response :success
  end

end

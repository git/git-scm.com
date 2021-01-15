# frozen_string_literal: true

require "test_helper"

class BooksControllerTest < ActionController::TestCase

  test "redirects old book site" do
    get :show, params: { lang: "1_welcome_to_git" }
    assert_redirected_to controller: "books", action: "show", lang: "en/Getting-Started"
  end

  test "gets the book page" do
    book = FactoryBot.create(:book, code: "en")
    get :show, params: { lang: "en" }
    assert_response :success
  end

  test "gets the book section page" do
  end

  test "gets the progit page" do
    section = FactoryBot.create(:section)
    get :chapter, params: { chapter: section.chapter.number, section: section.number }
    assert_response :success
  end

end

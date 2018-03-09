require 'rails_helper'

RSpec.describe SiteController, type: :controller do

  it "GET index" do
    get :index
    expect(response).to render_template("index")
  end

  it "GET search" do
    get :search, {search: "git-init"}
    expect(assigns(:term)).to eq("git-init")
    expect(response).to render_template("shared/_search")
  end

  it "GET search_results" do
    get :search_results, {search: "git-init"}
    expect(assigns(:term)).to eq("git-init")
    expect(response).to render_template("results")
  end

  it "GET svn" do
    get :svn
    expect(response).to render_template("svn")
  end

  it "GET redirect_wgibtx" do
    get :redirect_wgibtx
    expect(response).to redirect_to("https://git-scm.com/about")
  end

  describe "GET /book" do

    it "get /git-doc" do
      request.env["PATH_INFO"] = "/git-doc"
      get :redirect_book
      expect(response).to redirect_to("https://git-scm.com/git-doc")
    end

    it "get /" do
      get :redirect_book
      expect(response).to redirect_to("https://git-scm.com/book")
    end

  end

end

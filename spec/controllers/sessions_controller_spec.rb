require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  render_views

  before  do
    options = {
      provider: 'github',
      uid: '1234',
      info: {
        name: "Github User",
        nickname: "github-user"
      }
    }
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(options)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    controller.prepend_view_path 'app/views'
  end

  it "GET /new" do
    get :new
    response.status.should == 200
  end

  it "GET /create" do
    get :create
    User.exists?(github_id: 1234).should == true
  end

  it "GET /create with invalid credentials" do
    User.delete_all
    OmniAuth.config.mock_auth[:github] = :invalid_credentials
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    get :create
    User.exists?(uid: "1234").should == false
  end


end

require 'spec_helper'

describe SessionsController do

  before(:each) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: 'github',
      uid: '1234',
      info: {
        name: "Github User",
        nickname: "github-user"
      }
    })
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
  end

  it "GET /new" do
    get :new
    response.status.should == 200
  end

  it "GET /create" do
    get :create
    User.exists?(uid: "1234").should == true
  end

  it "GET /create with invalid credentials" do
    User.delete_all
    OmniAuth.config.mock_auth[:github] = :invalid_credentials
    rack.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    get :create
    User.exists?(uid: "1234").should == false
  end


end

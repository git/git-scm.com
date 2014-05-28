require 'spec_helper'

describe CommunityController do

  it "GET index" do
    get :index
    expect(response).to render_template("index")
  end

end

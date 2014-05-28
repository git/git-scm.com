require 'spec_helper'

describe AboutController do

  it "GET index" do
    get :index
    expect(assigns(:section)).to eq("about")
    expect(response).to render_template("index")
  end

end

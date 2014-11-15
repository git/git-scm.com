require 'rails_helper'

RSpec.describe AboutController, type: :controller do
  render_views

  before(:each) do
    controller.prepend_view_path 'app/views'
  end
  
  it "GET index" do
    get :index
    expect(assigns(:section)).to eq("about")
    expect(response).to render_template("index")
  end

end

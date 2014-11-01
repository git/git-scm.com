require 'rails_helper'

RSpec.describe CommunityController, type: :controller do
  render_views
  
  before(:each) do
    controller.prepend_view_path 'app/views'
  end

  it "GET index" do
    get :index
    expect(response).to render_template("index")
  end

end

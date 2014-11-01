require 'rails_helper'

describe User do


  context "Validation" do
    it "cannot save the new user" do
      user = User.new
      user.save.should == false
    end

    it "can save the new user" do
      user = User.new(screen_name: "test1", github_id: 0)
      user.save.should == true
    end
  end


  context "Token Generator" do
    it "generates remember token" do
      user = User.new(screen_name: "test2", github_id: 1)
      user.save.should == true
      user.remember_token.should_not == nil
    end
  end

end

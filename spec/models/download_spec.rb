require 'spec_helper'

describe Download do

  let(:version) { Fabricate(:version) }
  let(:download) { Fabricate(:download, version: version) }

  it { should belong_to :version }

  it "should have url" do
    download.url.should == "http://git-scm.com/git.zip"
  end
    
  it "should have version" do
    download.version == version
  end

end

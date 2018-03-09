require 'rails_helper'

RSpec.describe Download, type: :model do

  let(:version) { Fabricate(:version) }
  let(:download) { Fabricate(:download, version: version) }

  it { should belong_to :version }

  it "should have url" do
    expect(download.url).to eql('http://git-scm.com/git.zip')
  end

  it "should have version" do
    expect(download.version).to eql(version)
  end

end

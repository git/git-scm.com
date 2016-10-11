require 'spec_helper'
require 'rake'

def rake_task_invoke(task)
  Rake::Task[task].reenable
  Rake::Task[task].invoke
end

describe 'downloads.rake' do

  let(:download_rss) { File.read Rails.root.join("spec/data/downloads.rss").to_s }

  before :all do
    Rake.application.rake_require 'tasks/downloads'
    Rake::Task.define_task(:environment)
  end

  it "should have content" do
    stub_request(:any, "sourceforge.net").to_return(body: download_rss)
    Faraday.get(SOURCEFORGE_URL).body.should == download_rss
  end

  context "Download & Parse" do

    before :each do
      stub_request(:any, "sourceforge.net").to_return(body: download_rss)
    end

    describe "parse" do

      it "should have matching items" do
        rss = RSS::Parser.parse(download_rss)
        rss.items.first.link.should == "https://sourceforge.net/projects/git-osx-installer/files/git-1.9.0-intel-universal-snow-leopard.dmg/download"
        rss.items.first.pubDate.should == "Wed, 23 Apr 2014 15:00:54 +0000"
      end

    end

    describe "invoke downloads" do

      it "should have 2 downloads" do
        Download.count.should == 0
        rake_task_invoke "downloads"
        Download.count.should == 2
      end

      it "has link" do
        rake_task_invoke "downloads"
        Download.first.url.should == "https://sourceforge.net/projects/git-osx-installer/files/git-1.9.0-intel-universal-snow-leopard.dmg/download"
      end

      it "has published date" do
        rake_task_invoke "downloads"
        Download.first.release_date.should == "Wed, 23 Apr 2014 15:00:54 +0000"
      end

      it "has platform" do
        rake_task_invoke "downloads"
        Download.first.platform.should == "mac"
      end

    end
  end

end

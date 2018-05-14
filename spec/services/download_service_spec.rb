require 'rails_helper'

RSpec.describe DownloadService do
  subject { DownloadService }

  context 'windows', :vcr do
    before do
      subject.download_windows_versions
    end

    it 'reaches out to GitHub for releases' do
      expect(WebMock).to have_requested(:get, 'https://api.github.com/repos/git-for-windows/git/releases')
    end

    it 'creates Downloads with a windows platform' do
      expect(Download.first.platform).to include('windows')
    end

    it 'should have the correct download URL' do
      expect(Download.first.url).to include('https://github.com/git-for-windows/git/releases/download/')
    end
  end

  context 'mac', :vcr do
    before do
      subject.download_mac_versions
    end

    it 'reaches out to Sourceforge for releases' do
      expect(WebMock).to have_requested(:get, 'https://sourceforge.net/projects/git-osx-installer/rss?limit=20')
    end

    it 'creates Downloads with a mac platform' do
      expect(Download.first.platform).to eql('mac')
    end

    it 'should have the correct download URL' do
      expect(Download.first.url).to include('https://sourceforge.net/projects/git-osx-installer/files/')
    end
  end
end

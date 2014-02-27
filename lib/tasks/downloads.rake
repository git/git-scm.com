require 'octokit'
require 'feedzirra'

# [OvD] note that Google uses Atom & Sourceforge uses RSS
# however this isn't relevant when parsing the feeds for
# name, version, url & date with Feedzirra
GOOGLE_CODE_URL = "http://code.google.com/feeds/p/msysgit/downloads/basic"
SOURCEFORGE_URL = "http://sourceforge.net/api/file/index/project-id/2063428/mtime/desc/limit/20/rss"

def file_downloads(repository)
  downloads = []
  feed = Feedzirra::Feed.fetch_and_parse(repository)
  feed.entries.each do |entry|
    downloads << [entry.entry_id, entry.published]
  end
  downloads
end

def googlecode_url(project, filename)
  "https://#{project}.googlecode.com/files/#{filename}"
end

def sourceforge_url(project, filename)
  "http://sourceforge.net/projects/#{project}/files/#{filename}/download?use_mirror=autoselect"
end

# find newest mac and windows binary downloads
task :downloads => :environment do
  # find latest windows version
  project = "msysgit"
  win_downloads = file_downloads(GOOGLE_CODE_URL)
  win_downloads.each do |url, date|
    name = url.split('/').last
    if m = /^Git-(.*?)-(.*?)(\d{4})(\d{2})(\d{2})\.exe/.match(name)
      url = googlecode_url(project, name)
      version = m[1]
      puts version = version
      puts name
      puts url
      puts date
      puts
      v = Version.where(:name => version).first
      if v
        d = v.downloads.where(:url => url).first_or_create
        d.filename = name
        d.platform = 'windows'
        d.release_date = date
        d.save
      end
    end
  end

  # find latest mac version
  project = "git-osx-installer"
  mac_downloads = file_downloads(SOURCEFORGE_URL)
  mac_downloads.each do |url, date|
    name = url.split('/')[-2]
    if m = /git-(.*?)-/.match(name)
      url = sourceforge_url(project, name)
      version = m[1]
      puts version = version
      puts name
      puts url
      puts date
      puts
      v = Version.where(:name => version).first
      if v
        d = v.downloads.where(:url => url).first_or_create
        d.filename = name
        d.platform = 'mac'
        d.release_date = date
        d.save
      end
    end
  end
end

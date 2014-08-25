require 'octokit'
require 'open-uri'
require 'rss'

# [OvD] note that Google uses Atom & Sourceforge uses RSS
# however this isn't relevant when parsing the feeds for
# name, version, url & date with Feedzirra
SOURCEFORGE_URL = "http://sourceforge.net/api/file/index/project-id/2063428/mtime/desc/limit/20/rss"

def file_downloads(repository)
  downloads = []
  rss = open(repository).read
  feed = RSS::Parser.parse(rss)
  feed.items.each do |item|
    downloads << [item.link, item.pubDate]
  end
  downloads
end

def file_downloads_from_github(repository)
  downloads = []
  releases = Octokit.client.releases(repository)
  releases.each do |release|
    release.assets.each do |asset|
      url = ['https://github.com', repository, 'releases', 'download',
             release.tag_name, asset.name].join('/')

      downloads << [url, asset.updated_at]
    end
  end

  downloads
end

def sourceforge_url(project, filename)
  "http://sourceforge.net/projects/#{project}/files/#{filename}/download?use_mirror=autoselect"
end

# find newest mac and windows binary downloads
task :downloads => [:environment, :windows_downloads, :mac_downloads]

task :windows_downloads => :environment do
  # find latest windows version
  project = "msysgit"
  win_downloads = file_downloads_from_github("msysgit/msysgit")
  win_downloads.each do |url, date|
    name = url.split('/').last
    if m = /^Git-(.*?)-(.*?)(\d{4})(\d{2})(\d{2})\.exe/.match(name)
      version = m[1]
      puts version
      puts name
      puts url
      puts date
      puts
      if v = Version.where(name: version).first
        options = {version: v, url: url, filename: name, platform: 'windows', release_date: date}
        unless Download.exists?(options)
          d = Download.new(options)
          begin
            d.save
            puts "saved"
          rescue
            puts "error"
          end
          puts
        end
      end
    end
  end
end

task :mac_downloads => :environment do
  # find latest mac version
  project = "git-osx-installer"
  mac_downloads = file_downloads(SOURCEFORGE_URL)
  mac_downloads.each do |url, date|
    name = url.split('/')[-2]
    if m = /git-(.*?)-/.match(name)
      url = sourceforge_url(project, name)
      version = m[1]
      puts version
      puts name
      puts url
      puts date
      puts
      if v = Version.where(name: version).first
        options = {version: v, url: url, filename: name, platform: 'mac', release_date: date}
        unless Download.exists?(options)
          d = Download.new(options)
          begin
            d.save
            puts "saved"
          rescue
            puts "error"
          end
          puts
        end
      end
    end
  end
end

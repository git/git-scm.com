require 'octokit'
require 'feedzirra'

def gcode_downloads(project)
  downloads = []
  atom_url = "http://code.google.com/feeds/p/#{project}/downloads/basic"
  feed = Feedzirra::Feed.fetch_and_parse(atom_url)
  feed.entries.each do |entry|
    downloads << [entry.entry_id, entry.published]
  end
  downloads
end

# find newest mac and windows binary downloads
task :downloads => :environment do
  # find latest windows version
  win_downloads = gcode_downloads("msysgit")
  win_downloads.each do |url, date|
    name = url.split('/').last
    if m = /^Git-(.*?)-(.*?)(\d{4})(\d{2})(\d{2})\.exe/.match(name)
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
  mac_downloads = gcode_downloads("git-osx-installer")
  mac_downloads.each do |url, date|
    name = url.split('/').last
    if m = /git-(.*?)-/.match(name)
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

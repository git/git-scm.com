require 'octokit'

# find newest mac and windows binary downloads
task :downloads => :environment do
  # find latest windows version
  win_feed = "http://code.google.com/feeds/p/msysgit/downloads/basic"

  # find latest mac version
  mac_downloads = Octokit.downloads("timcharper/git_osx_installer")
  mac_downloads.each do |down|
    if m = /git-(.*?)-/.match(down.name)
      version = m[1]
      puts version = version
      puts url = down.html_url
      v = Version.where(:name => version).first
      d = v.downloads.where(:url => url).first_or_create
      d.filename = down.name
      d.platform = 'mac'
      d.save
    end
  end
end

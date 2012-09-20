require 'octokit'

# find newest mac and windows binary downloads
task :downloads => :environment do
  # find latest windows version
  win_downloads = Octokit.downloads("msysgit/git")
  win_downloads.each do |down|
    if m = /^Git-(.*?)-(.*).exe/.match(down.name)
      version = m[1]
      puts version = version
      puts url = down.html_url
      v = Version.where(:name => version).first
      if v
        d = v.downloads.where(:url => url).first_or_create
        d.filename = down.name
        d.platform = 'windows'
        d.save
      end
    end
  end

  # find latest mac version
  mac_downloads = Octokit.downloads("timcharper/git_osx_installer")
  mac_downloads.each do |down|
    if m = /git-(.*?)-/.match(down.name)
      version = m[1]
      puts version = version
      puts url = down.html_url
      v = Version.where(:name => version).first
      if v
        d = v.downloads.where(:url => url).first_or_create
        d.filename = down.name
        d.platform = 'mac'
        d.save
      end
    end
  end
end

require 'rss'

class DownloadService
  # [OvD] note that Google uses Atom & Sourceforge uses RSS
  # however this isn't relevant when parsing the feeds for
  # name, version, url & date with Feedzirra
  SOURCEFORGE_URL = 'https://sourceforge.net/projects/git-osx-installer/rss?limit=20'.freeze

  GIT_FOR_WINDOWS_REGEX           = /^(Portable|)Git-(\d+\.\d+\.\d+(?:\.\d+)?)-(?:.+-)*(32|64)-bit(?:\..*)?\.exe/
  GIT_FOR_WINDOWS_NAME_WITH_OWNER = 'git-for-windows/git'.freeze

  class << self
    def sourceforge_project_download_url(project, filename)
      "https://sourceforge.net/projects/#{project}/files/#{filename}/download?use_mirror=autoselect"
    end

    def download_windows_versions
      files_from_github(GIT_FOR_WINDOWS_NAME_WITH_OWNER).each do |name, date, url|
        # Git for Windows uses the following naming system
        # [Portable]Git-#.#.#.#[-dev-preview]-32/64-bit[.7z].exe
        match = GIT_FOR_WINDOWS_REGEX.match(name)

        next unless match

        portable = match[1]
        bitness  = match[3]

        # Git for windows sometimes creates extra releases all based off of the same upstream Git version
        # so we want to crop versions like 2.16.1.4 to just 2.16.1
        version_name = match[2].slice(/^\d+\.\d+\.\d+/)
        version = find_version_by_name(version_name)

        if version
          find_or_create_download(
              filename: name,
              platform: "windows#{bitness}#{portable}",
              release_date: date,
              version: version,
              url: url
          )
        else
          Rails.logger.info("Could not find version #{version_name}")
        end
      end
    end

    def download_mac_versions
      files_from_sourceforge(SOURCEFORGE_URL).each do |url, date|
        name  = url.split('/')[-2]
        match = /git-(.*?)-/.match(name)

        next unless match

        url  = sourceforge_project_download_url('git-osx-installer', name)
        name = match[1]

        version = find_version_by_name(name)

        if version
          find_or_create_download(
              filename: name,
              platform: 'mac',
              release_date: date,
              version: version,
              url: url
          )
        else
          Rails.logger.info("Could not find version #{name}")
        end
      end
    end

    private

    def files_from_github(repository)
      @octokit = Octokit::Client.new(:login => ENV['API_USER'], :password => ENV['API_PASS'])
      downloads = []
      releases  = @octokit.releases(repository)

      releases.each do |release|
        release.assets.each do |asset|
          downloads << [
            asset.name,
            asset.updated_at,
            asset.browser_download_url
          ]
        end
      end

      downloads
    end

    def files_from_sourceforge(repository)
      downloads = []
      rss       = open(repository).read
      feed      = RSS::Parser.parse(rss)

      feed.items.each do |item|
        downloads << [item.link, item.pubDate]
      end

      downloads
    end

    def find_or_create_download(filename:, platform:, release_date:, version:, url:)
      options = {
        filename:     filename,
        platform:     platform,
        release_date: release_date,
        version:      version,
        url:          url
      }

      if (download = Download.find_by(options))
        Rails.logger.info("Download record found #{download.inspect}")
      else
        begin
          download = Download.create!(options)
          Rails.logger.info("Download record created #{download.inspect}")
        rescue ActiveRecord::RecordInvalid => e
          Rail.logger.error("#{e.message}")
        end
      end
    end

    def find_version_by_name(name)
      # We assume the preindex rake task ran previously and saved possible new versions into the storage.
      # Otherwise this code should also create the versions, while the preindex task needs to be updated to deal
      # with versions imported by other tasks without importing the docs.
      # More details at https://github.com/git/git-scm.com/pull/1207.
      Version.find_by(name: name)
    end
  end
end

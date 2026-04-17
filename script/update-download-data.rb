#!/usr/bin/env ruby

# This is a simple script to update the download data in hugo.yml

require "logger"
require "octokit"
require "rss"
require "yaml"

$logger = Logger.new(STDERR)

class DownloadData
  # [OvD] note that Google uses Atom & Sourceforge uses RSS
  # however this isn't relevant when parsing the feeds for
  # name, version, url & date with Feedzirra
  GIT_FOR_WINDOWS_REGEX           = /^(Portable|)Git-(\d+\.\d+\.\d+(?:\.\d+)?)-(?:.+-)*(64-bit|arm64)(?:\..*)?\.exe/
  GIT_FOR_WINDOWS_NAME_WITH_OWNER = "git-for-windows/git"

  class << self
    def update_download_windows_versions(config)
      files_from_github(GIT_FOR_WINDOWS_NAME_WITH_OWNER).each do |name, date, url|
        # Git for Windows uses the following naming system
        # [Portable]Git-#.#.#.#[-dev-preview]-64-bit/arm64[.7z].exe
        match = GIT_FOR_WINDOWS_REGEX.match(name)

        next unless match

        portable = match[1]
        architecture = match[3]
        architecture = "x64" if architecture == "64-bit"

        # Git for windows sometimes creates extra releases all based off of the same upstream Git version
        # so we first want to crop versions like 2.16.1.4 to just 2.16.1
        version = match[2].slice(/^\d+\.\d+\.\d+/)
        # Now, as per Git for Windows' custom, append the fourth part in parens, e.g. 2.16.1(4)
        version += "(#{match[2].slice(version.length + 1)})" if match[2][version.length] == "."

        if version
          config["windows_installer"] = {} if config["windows_installer"].nil?
          win_config = config["windows_installer"]
          if portable.empty?
            key = "installer_#{architecture}"
          else
            key = "portable_#{architecture}"
          end
          win_config[key] = {} if win_config[key].nil?
          return if version_compare(version, win_config[key]["version"]) < 0
          win_config[key]["filename"] = name
          win_config[key]["release_date"] = date.strftime("%Y-%m-%d")
          win_config[key]["version"] = version
          win_config[key]["url"] = url
        else
          $logger.info("Could not find version #{version_name}")
        end
      end
    end

    private

    def files_from_github(repository)
      @octokit = Octokit::Client.new(access_token: ENV.fetch("GITHUB_API_TOKEN", nil))
      downloads = []
      releases  = @octokit.releases(repository)

      releases
        .reject { |release| release.prerelease || release.draft }
        .each do |release|
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

    def version_compare(a, b)
      a = a.nil? ? [] : a.gsub(/^v/, "").split(/[.()]/)
      b = b.nil? ? [] : b.gsub(/^v/, "").split(/[.()]/)
      while true
        a0 = a.shift
        b0 = b.shift
        return b0.nil? ? 0 : -1 if a0.nil?
        return +1 if b0.nil?
        diff = a0.to_i - b0.to_i
        return diff unless diff == 0
      end
    end
  end
end

config = YAML.load_file("hugo.yml")
config["params"] = {} if config["params"].nil?
DownloadData.update_download_windows_versions(config["params"])
yaml = YAML.dump(config).gsub(/ *$/, "")
File.write("hugo.yml", yaml)
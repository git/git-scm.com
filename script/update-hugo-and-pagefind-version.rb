#!/usr/bin/env ruby

require "logger"
require "octokit"
require "yaml"

$logger = Logger.new($stderr)

class ReleaseVersionUpdater
  REPOSITORIES = {
    "hugo_version" => "gohugoio/hugo",
    "pagefind_version" => "Pagefind/pagefind"
  }.freeze

  class << self
    def update(params)
      REPOSITORIES.each do |key, repository|
        update_param(params, key, repository)
      end
    end

    private

    def update_param(params, key, repository)
      current = params[key]
      latest = begin
        release = octokit.latest_release(repository)
        tag_or_name = release && (release.tag_name || release.name)
        tag_or_name && tag_or_name.to_s.sub(/^v/, "")
      rescue Octokit::NotFound
        $logger.warn("Repository #{repository} not found")
        nil
      rescue StandardError => e
        $logger.error("Failed to fetch releases for #{repository}: #{e.class} - #{e.message}")
        nil
      end

      if latest.nil?
        $logger.warn("No release found for #{repository}; keeping #{current.inspect}")
        return
      end

      if current.to_s == latest.to_s
        $logger.info("#{key} already at #{current}")
        return
      end

      params[key] = latest
      $logger.info("Updated #{key} to #{latest}")
    end

    def octokit
      @octokit ||= Octokit::Client.new(access_token: ENV.fetch("GITHUB_API_TOKEN", nil))
    end
  end
end

config = YAML.load_file("hugo.yml")
config["params"] ||= {}
ReleaseVersionUpdater.update(config["params"])
yaml = YAML.dump(config).gsub(/ *$/, "")
File.write("hugo.yml", yaml)
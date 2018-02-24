desc 'find newest mac and windows binary downloads'
namespace :downloads do
  desc 'find latest Windows version'
  task windows: :environment do
    Rails.logger = Logger.new(STDOUT)
    DownloadService.download_windows_versions
  end

  desc 'find latest Mac version'
  task mac: :environment do
    Rails.logger = Logger.new(STDOUT)
    DownloadService.download_mac_versions
  end
end

task downloads: ['downloads:windows', 'downloads:mac']

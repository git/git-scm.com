class DownloadsController < ApplicationController

  def index
  end

  def latest
    latest = Version.latest_version.name
    render :text => latest
  end

  def guis
    render "downloads/guis/index"
  end

  def logos
    render "downloads/logos/index"
  end

  def gui
    @platform = params[:platform]
    @platform = 'windows' if @platform == 'win'
    render "downloads/guis/index"
  end

  def download
    @platform = params[:platform]
    @platform = 'windows' if @platform == 'win'
    if @platform == 'mac'
      @project_url = "http://sourceforge.net/projects/git-osx-installer/"
      @source_url   = "https://github.com/git/git/"

      @download = Download.latest_for(@platform)
      @latest = Version.latest_version

      render "downloads/downloading"
    elsif @platform == 'windows'
      @project_url = "https://git-for-windows.github.io/"
      @source_url = "https://github.com/git-for-windows/git"

      @download32 = Download.latest_for(@platform + "32")
      @download64 = Download.latest_for(@platform + "64")
      @download32portable = Download.latest_for(@platform + "32Portable")
      @download64portable = Download.latest_for(@platform + "64Portable")
      @latest = Version.latest_version

      if request.env["HTTP_USER_AGENT"] =~ /WOW64|Win64/
        @download = @download64
        @bitness = "64-bit"
      else
        @download = @download32
        @bitness = "32-bit"
      end

      render "downloads/download_windows"
    elsif @platform == 'linux'
      render "downloads/download_linux"
    else
      redirect_to '/downloads'
    end
  rescue
    redirect_to '/downloads'
  end
end

class DownloadsController < ApplicationController

  def index
  end

  def latest
    latest = Version.latest_version.name
    render :text => latest
  end

  def guis
    guis_info = GuiPresenter.instance.guis_info

    render "downloads/guis/index", :locals => {:guis_info => guis_info}
  end

  def logos
    render "downloads/logos/index"
  end

  def gui
    @platform = params[:platform]
    @platform = 'windows' if @platform == 'win'

    guis_info = GuiPresenter.instance.guis_info

    render "downloads/guis/index", :locals => {:guis_info => guis_info}
  end

  def download
    @platform = params[:platform]
    @platform = 'windows' if @platform == 'win'
    if @platform == 'mac'
      @project_url = "https://sourceforge.net/projects/git-osx-installer/"
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

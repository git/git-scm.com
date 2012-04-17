class DownloadsController < ApplicationController
  layout "layout"

  def index
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
    if @platform == 'windows' || @platform == 'mac'

      @download = Download.latest_for(@platform)
      @latest = Version.latest_version

      render "downloads/download"
    elsif @platform == 'linux'
      render "downloads/download_linux"
    else
      redirect_to '/downloads'
    end
  rescue
    redirect_to '/downloads'
  end
end

class DownloadsController < ApplicationController
  layout "layout"

  def index
  end

  def guis
    render "downloads/guis/index"
  end

  def installers
    render "downloads/installers/index"
  end

  def logos
    render "downloads/logos/index"
  end

  def download
    @platform = params[:platform]
    @platform = 'windows' if @platform == 'win'
    if @platform == 'windows' || @platform == 'mac'

      if @platform == 'mac'
        @dl_link = "https://github.com/downloads/timcharper/git_osx_installer/git-1.7.9.4-intel-universal-snow-leopard.dmg"
      end

      if @platform == 'windows'
        @dl_link = "http://msysgit.googlecode.com/files/Git-1.7.10-preview20120409.exe"
      end

      render "downloads/download"
    elsif @platform == 'linux'
      render "downloads/download_linux"
    else
      redirect_to '/downloads/installers'
    end
  end
end

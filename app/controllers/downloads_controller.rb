# frozen_string_literal: true

class DownloadsController < ApplicationController
  def index; end

  def latest
    latest = Version.latest_version.name
    render text: latest
  end

  def guis
    guis_info = GuiPresenter.instance.guis_info

    render "downloads/guis/index", locals: { guis_info: guis_info }
  end

  def logos
    render "downloads/logos/index"
  end

  def gui
    @platform = params[:platform]
    @platform = "windows" if @platform == "win"

    guis_info = GuiPresenter.instance.guis_info

    render "downloads/guis/index", locals: { guis_info: guis_info }
  end

  def download
    @platform = params[:platform]
    @platform = "windows" if @platform == "win"
    @latest = Version.latest_version
    case @platform
    when "mac"
      @download = Download.latest_for(@platform)

      render "downloads/download_mac"
    when "windows"
      @project_url = "https://git-for-windows.github.io/"
      @source_url = "https://github.com/git-for-windows/git"

      @download32 = Download.latest_for(@platform + "32")
      @download64 = Download.latest_for(@platform + "64")
      @download32portable = Download.latest_for(@platform + "32Portable")
      @download64portable = Download.latest_for(@platform + "64Portable")

      if /WOW64|Win64|x64|x86_64/.match?(request.env["HTTP_USER_AGENT"])
        @download = @download64
        @bitness = "64-bit"
      else
        @download = @download32
        @bitness = "32-bit"
      end

      render "downloads/download_windows"
    when "linux"
      render "downloads/download_linux"
    else
      redirect_to "/downloads"
    end
  rescue StandardError
    redirect_to "/downloads"
  end
end

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
end

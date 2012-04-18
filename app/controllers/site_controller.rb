require 'pp'
class SiteController < ApplicationController
  layout "layout"

  def index
  end

  def admin
    @downloads = Download.all
  end

  def search
    sname = params['search'].downcase

    @data = {
      :term => sname,
      :results => []
    }

    if results = Doc.search(sname)
      @data[:results] << results
    end

    if results = Section.search(sname)
      @data[:results] << results
    end

    render :partial => 'shared/search'
  end
end

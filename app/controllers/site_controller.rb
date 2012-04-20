require 'pp'
class SiteController < ApplicationController
  layout "layout"

  def index
  end

  def admin
    @downloads = Download.all
  end

  def search
    @term = sname = params['search'].to_s.downcase
    @data = search_term(sname)
    render :partial => 'shared/search'
  end

  def search_results
    @term = sname = params['search'].to_s.downcase
    data = search_term(sname, true)
    @top = []
    @rest = []
    data[:results].each do |type|
      type[:matches].each do |hit|
        if hit[:score] >= 1.0
          @top << hit
        else 
          @rest << hit
        end
      end
    end
    @top.sort! { |a, b| b[:score] <=> a[:score] }
    @rest.sort! { |a, b| b[:score] <=> a[:score] }
    render "results"
  end

  def search_term(sname, highlight = false)
    data = {
      :term => sname,
      :results => []
    }

    if results = Doc.search(sname, highlight)
      data[:results] << results
    end

    if results = Section.search(sname, 'en', highlight)
      data[:results] << results
    end

    data
  end
end

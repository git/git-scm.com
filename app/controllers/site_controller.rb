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

  def svn
  end

  def redirect_wgibtx
    redirect_to "http://git-scm.com/about"
  end
  
  # like '5_submodules.html', etc
  def redirect_combook
    current_uri = request.env['PATH_INFO'].gsub('/', '')
    if slug = REDIRECT[current_uri]
      redirect_to "http://git-scm.com/book/#{slug}"
    else
      redirect_to "http://git-scm.com/book" 
    end
  end

  def redirect_book
    current_uri = request.env['PATH_INFO']
    if current_uri == '/'
      redirect_to "http://git-scm.com/book" 
    else
      redirect_to "http://git-scm.com#{current_uri}"
    end
  end
end

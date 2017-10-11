class SiteController < ApplicationController

  def index
    expires_in 10.minutes, :public => true

    @section    = "home"
    @subsection = ""
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

    if results = Doc.search(sname)
      data[:results] << results
    end

    if results = Section.search(sname, :lang => 'en')
      data[:results] << results
    end

    data
  end

  def svn
  end

  def redirect_wgibtx
    redirect_to "https://git-scm.com/about"
  end

  def redirect_book
    current_uri = request.env['PATH_INFO']
    if current_uri == '/'
      redirect_to "https://git-scm.com/book"
    else
      redirect_to "https://git-scm.com#{current_uri}"
    end
  end

end

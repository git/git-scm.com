class LibraryController < ApplicationController
  layout 'library'

  def api
    @version = params[:version] || 'HEAD'
  end

  def function
    @function = Function.where(:name => params[:fname]).first
    render_404 unless @function
  end

  def render_404
    raise ActionController::RoutingError.new('Not Found')
  end
end

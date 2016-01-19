class LibraryController < ApplicationController
  layout 'library'

  def api
  end

  def group
    @group = Group.find(params[:gname], params[:version])
    render_404 unless @group
  end

  def function
    @function = Function.find(params[:fname], params[:version])
    render_404 unless @function
  end

  def render_404
    raise ActionController::RoutingError.new('Not Found')
  end
end

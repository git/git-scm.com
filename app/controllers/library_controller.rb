class LibraryController < ApplicationController
  layout 'library'

  def api
  end

  def group
    @group = Group.where(:version => params[:version], :name => params[:gname]).first
    render_404 unless @group
  end

  def function
    @function = Function.where(:version => params[:version], :name => params[:fname]).first
    render_404 unless @function
  end

  def render_404
    raise ActionController::RoutingError.new('Not Found')
  end
end

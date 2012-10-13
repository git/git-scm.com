class LibraryController < ApplicationController
  layout 'library'

  def api
    @version = params[:version] || 'HEAD'
    @groups = Group.where(:version => @version).to_a
  end
end

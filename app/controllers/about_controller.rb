# frozen_string_literal: true

class AboutController < ApplicationController

  def index
    @section = "about"
    set_title "About"

    return render "about/index" unless params.key?(:section)

    begin
      render "about/#{params[:section].to_s.underscore}" # rubocop:disable GitHub/RailsControllerRenderLiteral
    rescue ActionView::MissingTemplate
      raise PageNotFound
    end
  end
end

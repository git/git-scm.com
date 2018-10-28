# frozen_string_literal: true

class AboutController < ApplicationController

  def index
    @section = "about"
    set_title "About"
  end

end

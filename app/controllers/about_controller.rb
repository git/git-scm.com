# frozen_string_literal: true

class AboutController < ApplicationController
  def index
    @section = "about"
    title "About"
  end
end

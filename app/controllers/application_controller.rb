class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :determine_os

  # Mac, Windows, Linux are valid
  def determine_os
    @os = 'linux'
  end
end

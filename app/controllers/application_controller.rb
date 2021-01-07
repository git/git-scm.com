# frozen_string_literal: true

PageNotFound = Class.new(Exception)

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :determine_os

  rescue_from PageNotFound, with: :page_not_found

  # Mac, Windows, Linux are valid
  def determine_os
    @os = "linux"
  end

  def set_title(title)
    @page_title = "#{title} - Git"
  end

  private

  def page_not_found
    render file: not_found_template, layout: false
  end

  def not_found_template
    Rails.root.join("public/404.html")
  end

end

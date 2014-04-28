PageNotFound = Class.new(Exception)

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :determine_os
  helper_method :current_user, :signed_in?

  rescue_from PageNotFound, :with => :page_not_found

  # Mac, Windows, Linux are valid
  def determine_os
    @os = 'linux'
  end

  def set_title(title)
    @page_title = "#{title} - Git"
  end

  def current_user
    @current_user ||= User.where(remember_token: session[:remember_token]).first
  end

  def authenticate
    unless signed_in?
      redirect_to sign_in_path
    end
  end

  def signed_in?
    current_user.present?
  end


  private

  def page_not_found
    render :file => not_found_template, :layout => false
  end

  def not_found_template
    File.join(Rails.root, "public/404.html")
  end

end

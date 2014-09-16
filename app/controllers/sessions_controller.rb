class SessionsController < ApplicationController
  
  def new
  end

  def create
    create_session
    redirect_to root_path
  end

  def destroy
    destroy_session
    redirect_to root_path
  end

  private

  def create_session
    user = User.where(github_id: github_id).first_or_initialize
    user.screen_name = github_username
    user.save!
    session[:remember_token] = user.remember_token
  end

  def destroy_session
    session[:remember_token] = nil
  end

  def github_id
    env['omniauth.auth']['uid']
  end

  def github_username
    env['omniauth.auth']['info']['nickname']
  end

end

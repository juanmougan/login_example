class HomeController < ApplicationController
  def index
    redirect_to dashboard_path if rodauth.logged_in?
  end
end

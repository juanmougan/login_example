class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @account = current_account
  end

  private

  def authenticate_user!
    rodauth.require_authentication
  end
end

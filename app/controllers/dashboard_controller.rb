class DashboardController < ApplicationController
  before_action -> { rodauth.require_authentication }

  def index
    @account = rodauth.rails_account
  end
end

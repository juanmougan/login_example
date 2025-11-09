class ApplicationController < ActionController::Base
  include Rodauth::Rails::ControllerMethods
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def authenticate_user!
    rodauth.require_authentication
  end

  # TODO is this YAGNI?
  # def rodauth
  #   Rodauth::Rails.rodauth
  # end

  def current_account
    @current_account ||= rodauth.rails_account
  end

  helper_method :rodauth, :current_account
end

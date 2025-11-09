module Api
  module V1
    class BaseController < ActionController::API
      private

      def rodauth
        Rodauth::Rails.rodauth
      end

      def current_account
        @current_account ||= rodauth.rails_account if rodauth.logged_in?
      end

      def authenticate_api_user!
        rodauth.require_authentication
      end
    end
  end
end

module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_api_user!

      def show
        render json: {
          id: current_account.id,
          name: current_account.name,
          email: current_account.email,
          status: current_account.status_id
        }
      end

      def destroy
        if current_account.destroy
          rodauth.logout
          render json: { message: "Account deleted successfully" }, status: :ok
        else
          render json: {
            error: "Failed to delete account",
            details: current_account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end

module Api
  module V1
    class BaseController < ActionController::API
      before_action :check_login

      private

      def check_login
        render( json: { Error: 'access denied' }, status: 401 ) unless current_user
      end
    end
  end
end

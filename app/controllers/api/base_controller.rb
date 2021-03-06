module Api
  class BaseController < ActionController::Base
    include ActionController::HttpAuthentication::Token
    before_action :authenticate_user_from_token!

    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      render json: { message: exception.message }, status: :forbidden
    end

    attr_reader :current_account
    helper_method :current_account

    private def authenticate_user_from_token!
      auth_params, _options = token_and_options(request)
      user_id, auth_token  = auth_params && auth_params.split(':', 2)
      user                 = user_id && User.find(user_id)

      if user && Devise.secure_compare(user.authentication_token, auth_token)
        sign_in user, store: false
        @current_user = user
        @current_account = user.account
      else
        message = "HTTP Token: Access denied."
        render json: { code: "authentication.missing", message: message }, status: :forbidden
      end
    end
  end
end

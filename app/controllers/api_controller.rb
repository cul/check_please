# frozen_string_literal: true

class ApiController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  rescue_from ActiveRecord::RecordNotFound do
    render json: errors('Not Found'), status: :not_found
  end

  private

  # Returns 406 status if format requested is not json. This method can be
  # used as a before_action callback for any controllers that only respond
  # to json.
  def ensure_json_request
    return if request.format.blank? || request.format == :json

    head :not_acceptable
  end

  # Renders with an :unauthorized status if no request token is provided, or renders with a
  # :forbidden status if the request uses an invalid request token. This method should be
  # used as a before_action callback for any controller actions that require authorization.
  def authenticate_request_token
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(CHECK_PLEASE['remote_request_api_key'], token)
    end
  end

  # Generates JSON with errors
  #
  # @param String|Array json response describing errors
  def errors(errors)
    { errors: Array.wrap(errors).map { |e| { message: e } } }
  end
end

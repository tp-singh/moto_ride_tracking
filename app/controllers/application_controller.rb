class ApplicationController < ActionController::API
  before_action :authenticate_request!

  rescue_from AuthenticationError,           with: :render_unauthorized
  rescue_from NotFoundError,                 with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound,  with: :render_not_found

  private

  def authenticate_request!
    header = request.headers['Authorization']
    raise AuthenticationError, 'Missing token' unless header&.start_with?('Bearer ')

    token   = header.split(' ').last
    payload = AuthService.decode_access_token(token)
    user_id = payload['sub']
    @current_user = Rails.cache.fetch("auth_user:#{user_id}", expires_in: 60.seconds) do
      User.find(user_id)
    end
  rescue ActiveRecord::RecordNotFound
    raise AuthenticationError, 'User not found'
  end

  def current_user
    @current_user
  end

  def render_unauthorized(e)
    render json: { error: e.message }, status: :unauthorized
  end

  def render_not_found(_e = nil)
    render json: { error: 'Not found' }, status: :not_found
  end

  def render_created(data)
    render json: data, status: :created
  end

  def render_ok(data)
    render json: data, status: :ok
  end
end

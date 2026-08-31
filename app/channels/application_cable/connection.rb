module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token] || request.headers['Authorization']&.split(' ')&.last
      reject_unauthorized_connection unless token

      payload = AuthService.decode_access_token(token)
      User.find(payload['sub'])
    rescue AuthenticationError, ActiveRecord::RecordNotFound
      reject_unauthorized_connection
    end
  end
end

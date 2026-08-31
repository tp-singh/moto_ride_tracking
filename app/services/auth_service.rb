class AuthService
  JWT_ALGORITHM = 'HS256'.freeze

  def self.decode_access_token(token)
    decoded = JWT.decode(token, jwt_secret, true, algorithm: JWT_ALGORITHM)
    decoded.first
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    raise AuthenticationError, e.message
  end

  def self.jwt_secret
    ENV.fetch('JWT_SECRET') { raise 'JWT_SECRET not set' }
  end
  private_class_method :jwt_secret
end

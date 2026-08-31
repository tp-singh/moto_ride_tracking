module AuthHelpers
  def auth_token_for(user)
    payload = { 'sub' => user.id.to_s, 'exp' => 1.hour.from_now.to_i }
    JWT.encode(payload, ENV.fetch('JWT_SECRET'), 'HS256')
  end

  def auth_headers_for(user)
    { 'Authorization' => "Bearer #{auth_token_for(user)}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end

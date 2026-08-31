require 'rails_helper'

RSpec.describe AuthService do
  let(:user) { create(:user) }
  let(:secret) { ENV.fetch('JWT_SECRET') }

  def encode_token(payload)
    JWT.encode(payload, secret, 'HS256')
  end

  describe '.decode_access_token' do
    it 'returns the payload for a valid token' do
      token = encode_token({ 'sub' => user.id.to_s, 'exp' => 1.hour.from_now.to_i })
      result = AuthService.decode_access_token(token)
      expect(result['sub']).to eq(user.id.to_s)
    end

    it 'raises AuthenticationError for an expired token' do
      token = encode_token({ 'sub' => user.id.to_s, 'exp' => 1.hour.ago.to_i })
      expect { AuthService.decode_access_token(token) }
        .to raise_error(AuthenticationError)
    end

    it 'raises AuthenticationError for a tampered token' do
      expect { AuthService.decode_access_token('not.a.jwt') }
        .to raise_error(AuthenticationError)
    end
  end
end

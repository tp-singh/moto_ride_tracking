require 'rails_helper'

RSpec.describe 'GET /api/v1/rides/:ride_id/riders', type: :request do
  let(:user)   { create(:user) }
  let(:rider2) { create(:user) }
  let(:ride)   { create(:ride, status: 'active') }
  let!(:membership)  { create(:ride_membership, ride: ride, user: user,   status: 'active') }
  let!(:membership2) { create(:ride_membership, ride: ride, user: rider2, status: 'active') }

  let(:redis_double) do
    d = double('redis_conn')
    allow(d).to receive(:hgetall).and_return({})
    d
  end

  before do
    allow(REDIS).to receive(:hgetall).and_return({})
  end

  context 'as an active member' do
    it 'returns 200 with rider list' do
      get "/api/v1/rides/#{ride.public_id}/riders",
          headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['riders'].length).to eq(2)
    end

    it 'includes user name and role' do
      get "/api/v1/rides/#{ride.public_id}/riders",
          headers: auth_headers_for(user)
      rider = response.parsed_body['riders'].find { |r| r['user_id'] == user.id }
      expect(rider['name']).to eq(user.name)
      expect(rider['role']).to eq('rider')
    end

    it 'excludes riders with left status' do
      left_user = create(:user)
      create(:ride_membership, ride: ride, user: left_user, status: 'left')
      get "/api/v1/rides/#{ride.public_id}/riders",
          headers: auth_headers_for(user)
      user_ids = response.parsed_body['riders'].map { |r| r['user_id'] }
      expect(user_ids).not_to include(left_user.id)
    end

    it 'shows offline status when no Redis location' do
      get "/api/v1/rides/#{ride.public_id}/riders",
          headers: auth_headers_for(user)
      rider = response.parsed_body['riders'].first
      expect(rider['rider_status']).to eq('offline')
    end
  end

  context 'without auth' do
    it 'returns 401' do
      get "/api/v1/rides/#{ride.public_id}/riders"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

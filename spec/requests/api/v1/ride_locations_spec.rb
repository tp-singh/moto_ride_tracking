require 'rails_helper'

RSpec.describe 'POST /api/v1/rides/:ride_id/locations', type: :request do
  let(:user)  { create(:user) }
  let(:ride)  { create(:ride, status: 'active') }
  let!(:membership) { create(:ride_membership, ride: ride, user: user, status: 'active') }

  let(:valid_params) do
    {
      latitude:     28.6139,
      longitude:    77.2090,
      rider_status: 'riding',
      recorded_at:  Time.current.iso8601
    }
  end

  let(:redis_double) do
    d = double('redis_conn')
    allow(d).to receive(:hset)
    allow(d).to receive(:hget).and_return(nil)
    allow(d).to receive(:expire)
    allow(d).to receive(:setex)
    allow(d).to receive(:set).and_return(true)
    allow(d).to receive(:pipelined).and_yield(d)
    d
  end

  before do
    allow(REDIS).to receive(:with).and_yield(redis_double)
    allow(REDIS).to receive(:set).and_return(true)
    allow(ActionCable.server).to receive(:broadcast)
    allow(TrackArchiveJob).to receive(:perform_async)
    allow(GroupIntelligenceJob).to receive(:perform_async)
  end

  context 'with valid auth and membership' do
    it 'returns 204 no content' do
      post "/api/v1/rides/#{ride.public_id}/locations",
           params: valid_params,
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:no_content)
    end

    it 'broadcasts location via ActionCable' do
      post "/api/v1/rides/#{ride.public_id}/locations",
           params: valid_params,
           headers: auth_headers_for(user)
      expect(ActionCable.server).to have_received(:broadcast)
        .with("ride_#{ride.id}", hash_including(type: 'location_updated'))
    end

    it 'accepts batch location array' do
      locations = [valid_params, valid_params.merge(latitude: 28.6200)]
      post "/api/v1/rides/#{ride.public_id}/locations",
           params: { locations: locations },
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:no_content)
    end
  end

  context 'without auth token' do
    it 'returns 401' do
      post "/api/v1/rides/#{ride.public_id}/locations", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when ride does not exist' do
    it 'returns 404' do
      post '/api/v1/rides/RID-XXXX/locations',
           params: valid_params,
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when user is not a member of the ride' do
    it 'returns 401' do
      other_user = create(:user)
      post "/api/v1/rides/#{ride.public_id}/locations",
           params: valid_params,
           headers: auth_headers_for(other_user)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when ride is not active' do
    it 'returns 401' do
      draft_ride = create(:ride, status: 'draft')
      create(:ride_membership, ride: draft_ride, user: user, status: 'active')
      post "/api/v1/rides/#{draft_ride.public_id}/locations",
           params: valid_params,
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

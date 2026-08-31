require 'rails_helper'

RSpec.describe 'POST /api/v1/rides/:ride_id/emergency_events', type: :request do
  let(:user)   { create(:user) }
  let(:ride)   { create(:ride, status: 'active') }
  let!(:membership) { create(:ride_membership, ride: ride, user: user, status: 'active') }

  let(:valid_params) do
    { event_type: 'sos', latitude: 28.6139, longitude: 77.2090 }
  end

  before do
    allow(ActionCable.server).to receive(:broadcast)
    allow(PushNotificationJob).to receive(:perform_later)
  end

  context 'with valid auth and membership' do
    it 'returns 201 with the event' do
      post "/api/v1/rides/#{ride.public_id}/emergency_events",
           params: valid_params,
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body['event_type']).to eq('sos')
    end

    it 'creates an EmergencyEvent record' do
      expect {
        post "/api/v1/rides/#{ride.public_id}/emergency_events",
             params: valid_params,
             headers: auth_headers_for(user)
      }.to change(EmergencyEvent, :count).by(1)
    end

    it 'broadcasts emergency_created' do
      post "/api/v1/rides/#{ride.public_id}/emergency_events",
           params: valid_params,
           headers: auth_headers_for(user)
      expect(ActionCable.server).to have_received(:broadcast)
        .with("ride_#{ride.id}", hash_including(type: 'emergency_created'))
    end
  end

  context 'without auth token' do
    it 'returns 401' do
      post "/api/v1/rides/#{ride.public_id}/emergency_events", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when user is not a member' do
    it 'returns 401' do
      stranger = create(:user)
      post "/api/v1/rides/#{ride.public_id}/emergency_events",
           params: valid_params,
           headers: auth_headers_for(stranger)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when ride is not live' do
    it 'returns 401' do
      finished_ride = create(:ride, status: 'draft')
      create(:ride_membership, ride: finished_ride, user: user, status: 'active')
      post "/api/v1/rides/#{finished_ride.public_id}/emergency_events",
           params: valid_params,
           headers: auth_headers_for(user)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

require 'rails_helper'

RSpec.describe Emergencies::TriggerEmergencyService do
  let(:ride) { create(:ride) }
  let(:user) { create(:user) }

  let(:params) do
    { event_type: 'sos', latitude: 28.6139, longitude: 77.2090, notes: 'Need help' }
  end

  before do
    allow(ActionCable.server).to receive(:broadcast)
    allow(PushNotificationJob).to receive(:perform_later)
  end

  describe '.call' do
    it 'creates an EmergencyEvent record' do
      expect { described_class.call(ride: ride, user: user, params: params) }
        .to change(EmergencyEvent, :count).by(1)
    end

    it 'returns the created event' do
      event = described_class.call(ride: ride, user: user, params: params)
      expect(event).to be_a(EmergencyEvent)
      expect(event).to be_persisted
    end

    it 'sets event_type from params' do
      event = described_class.call(ride: ride, user: user, params: params)
      expect(event.event_type).to eq('sos')
    end

    it 'defaults event_type to sos when not provided' do
      event = described_class.call(ride: ride, user: user, params: params.except(:event_type))
      expect(event.event_type).to eq('sos')
    end

    it 'broadcasts emergency_created over ActionCable' do
      described_class.call(ride: ride, user: user, params: params)
      expect(ActionCable.server).to have_received(:broadcast)
        .with("ride_#{ride.id}", hash_including(type: 'emergency_created', user_id: user.id))
    end

    it 'enqueues PushNotificationJob with SOS title' do
      described_class.call(ride: ride, user: user, params: params)
      expect(PushNotificationJob).to have_received(:perform_later)
        .with(hash_including(title: '🚨 SOS Alert', exclude_id: user.id))
    end

    it 'enqueues PushNotificationJob with warning title for mechanical event' do
      described_class.call(ride: ride, user: user, params: params.merge(event_type: 'mechanical'))
      expect(PushNotificationJob).to have_received(:perform_later)
        .with(hash_including(title: '⚠️ Rider Alert'))
    end
  end

  describe '.call with auth service spec' do
    it 'raises RecordInvalid for invalid event_type' do
      expect {
        described_class.call(ride: ride, user: user, params: params.merge(event_type: 'invalid'))
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

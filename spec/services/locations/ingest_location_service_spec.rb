require 'rails_helper'

RSpec.describe Locations::IngestLocationService do
  let(:ride) { create(:ride) }
  let(:user) { create(:user) }

  let(:valid_payload) do
    {
      latitude:    28.6139,
      longitude:   77.2090,
      altitude:    216.0,
      speed:       15.0,
      heading:     45.0,
      accuracy:    10.0,
      rider_status: 'riding',
      battery_level: 80,
      gps_state:    'good',
      network_state: 'online',
      recorded_at:  Time.current.iso8601
    }
  end

  let(:redis_double) do
    d = double('redis_conn')
    allow(d).to receive(:hset)
    allow(d).to receive(:expire)
    allow(d).to receive(:setex)
    allow(d).to receive(:hget).and_return(nil)
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

  describe '.call' do
    it 'broadcasts location_updated over ActionCable' do
      described_class.call(ride: ride, user: user, payload: valid_payload)
      expect(ActionCable.server).to have_received(:broadcast)
        .with("ride_#{ride.id}", hash_including(type: 'location_updated', user_id: user.id))
    end

    it 'stores location blob in Redis' do
      described_class.call(ride: ride, user: user, payload: valid_payload)
      expect(redis_double).to have_received(:hset)
        .with("ride:#{ride.id}:locations", user.id.to_s, anything)
    end

    it 'enqueues TrackArchiveJob for bucketed persistence' do
      described_class.call(ride: ride, user: user, payload: valid_payload)
      expect(TrackArchiveJob).to have_received(:perform_async)
    end

    it 'enqueues GroupIntelligenceJob when throttle key is fresh' do
      described_class.call(ride: ride, user: user, payload: valid_payload)
      expect(GroupIntelligenceJob).to have_received(:perform_async).with(ride.id)
    end
  end

  describe '.valid?' do
    it 'returns true for a valid payload' do
      expect(described_class.send(:valid?, valid_payload)).to be true
    end

    it 'rejects zero lat/lng (null island)' do
      expect(described_class.send(:valid?, valid_payload.merge(latitude: 0, longitude: 0))).to be false
    end

    it 'rejects latitude out of range' do
      expect(described_class.send(:valid?, valid_payload.merge(latitude: 95))).to be false
    end

    it 'rejects unrealistic speed' do
      expect(described_class.send(:valid?, valid_payload.merge(speed: 150))).to be false
    end

    it 'rejects accuracy worse than 500m' do
      expect(described_class.send(:valid?, valid_payload.merge(accuracy: 600))).to be false
    end

    it 'rejects stale timestamps' do
      stale = 10.minutes.ago.iso8601
      expect(described_class.send(:valid?, valid_payload.merge(recorded_at: stale))).to be false
    end

    it 'rejects future timestamps beyond 30 seconds' do
      future = 2.minutes.from_now.iso8601
      expect(described_class.send(:valid?, valid_payload.merge(recorded_at: future))).to be false
    end

    it 'accepts blank recorded_at by substituting current time' do
      # parse_time returns Time.current for blank values — treated as now, which is valid
      expect(described_class.send(:valid?, valid_payload.merge(recorded_at: ''))).to be true
    end
  end
end

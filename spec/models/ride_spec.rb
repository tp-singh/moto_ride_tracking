require 'rails_helper'

RSpec.describe Ride, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:leader).class_name('User') }
    it { is_expected.to have_many(:ride_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:ride_locations).dependent(:destroy) }
    it { is_expected.to have_many(:ride_track_points).dependent(:destroy) }
    it { is_expected.to have_many(:emergency_events).dependent(:destroy) }
  end

  describe 'scopes' do
    it '.active_rides returns only active rides' do
      active = create(:ride, status: 'active')
      create(:ride, status: 'paused')
      create(:ride, status: 'draft')
      expect(Ride.active_rides).to contain_exactly(active)
    end
  end

  describe '#active?' do
    it 'returns true when status is active' do
      expect(build(:ride, status: 'active')).to be_active
    end

    it 'returns false for other statuses' do
      expect(build(:ride, status: 'paused')).not_to be_active
    end
  end

  describe '#paused?' do
    it 'returns true when status is paused' do
      expect(build(:ride, status: 'paused')).to be_paused
    end
  end

  describe '#live?' do
    it 'returns true for active ride' do
      expect(build(:ride, status: 'active')).to be_live
    end

    it 'returns true for paused ride' do
      expect(build(:ride, status: 'paused')).to be_live
    end

    it 'returns false for draft ride' do
      expect(build(:ride, status: 'draft')).not_to be_live
    end
  end
end

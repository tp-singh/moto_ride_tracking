require 'rails_helper'

RSpec.describe RideMembership, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:ride) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:vehicle).optional }
  end

  describe 'scopes' do
    it '.active_members returns joined and active memberships' do
      ride = create(:ride)
      active  = create(:ride_membership, ride: ride, status: 'active')
      joined  = create(:ride_membership, ride: ride, status: 'joined')
      pending = create(:ride_membership, ride: ride, status: 'pending')
      left    = create(:ride_membership, ride: ride, status: 'left')
      expect(RideMembership.active_members).to contain_exactly(active, joined)
    end
  end

  describe '#active?' do
    it 'returns true for joined status' do
      expect(build(:ride_membership, status: 'joined')).to be_active
    end

    it 'returns true for active status' do
      expect(build(:ride_membership, status: 'active')).to be_active
    end

    it 'returns false for left status' do
      expect(build(:ride_membership, status: 'left')).not_to be_active
    end
  end
end

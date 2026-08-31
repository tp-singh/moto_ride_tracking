require 'rails_helper'

RSpec.describe RideLocation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:ride) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:rider_status).in_array(RideLocation::RIDER_STATUSES) }
    it { is_expected.to validate_presence_of(:recorded_at) }
  end
end

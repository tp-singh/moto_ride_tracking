require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:ride_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:devices).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid user' do
      expect(build(:user)).to be_valid
    end
  end
end

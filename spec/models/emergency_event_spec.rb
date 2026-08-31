require 'rails_helper'

RSpec.describe EmergencyEvent, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:ride) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resolved_by).class_name('User').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:event_type).in_array(EmergencyEvent::EVENT_TYPES) }
  end

  describe '#resolve!' do
    it 'sets resolved_by and resolved_at' do
      event    = create(:emergency_event)
      resolver = create(:user)
      event.resolve!(resolver)
      expect(event.resolved_by).to eq(resolver)
      expect(event.resolved_at).to be_present
    end
  end

  describe '#resolved?' do
    it 'returns false when not resolved' do
      expect(build(:emergency_event)).not_to be_resolved
    end

    it 'returns true after resolution' do
      event = create(:emergency_event)
      event.resolve!(create(:user))
      expect(event).to be_resolved
    end
  end
end

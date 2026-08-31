class EmergencyEvent < ApplicationRecord
  belongs_to :ride
  belongs_to :user
  belongs_to :resolved_by, class_name: 'User', optional: true

  EVENT_TYPES = %w[sos mechanical medical accident fuel other].freeze
  validates :event_type, inclusion: { in: EVENT_TYPES }

  def resolve!(resolver)
    update!(resolved_by: resolver, resolved_at: Time.current)
  end

  def resolved?; resolved_at.present?; end
end

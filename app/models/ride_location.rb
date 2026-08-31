class RideLocation < ApplicationRecord
  belongs_to :ride
  belongs_to :user

  RIDER_STATUSES = %w[riding stopped offline paused fuel_stop break mechanical sos].freeze
  GPS_STATES     = %w[good degraded unavailable].freeze
  NETWORK_STATES = %w[online offline].freeze

  validates :rider_status, inclusion: { in: RIDER_STATUSES }
  validates :recorded_at, presence: true
end

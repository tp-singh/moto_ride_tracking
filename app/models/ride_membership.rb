class RideMembership < ApplicationRecord
  self.table_name = 'ride_memberships'

  belongs_to :ride
  belongs_to :user
  belongs_to :vehicle, optional: true

  ROLES    = %w[rider marshal captain].freeze
  STATUSES = %w[pending invited joined active left removed].freeze

  scope :active_members, -> { where(status: %w[joined active]) }

  def active?; %w[joined active].include?(status); end
end

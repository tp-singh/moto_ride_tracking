class Ride < ApplicationRecord
  self.table_name = 'rides'

  belongs_to :leader, class_name: 'User'
  has_many :ride_memberships, dependent: :destroy
  has_many :ride_locations, dependent: :destroy
  has_many :ride_track_points, dependent: :destroy
  has_many :emergency_events, dependent: :destroy

  scope :active_rides, -> { where(status: 'active') }

  def active?; status == 'active'; end
  def paused?; status == 'paused'; end
  def live?;   %w[active paused].include?(status); end
end

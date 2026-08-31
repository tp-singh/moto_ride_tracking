class RideTrackPoint < ApplicationRecord
  belongs_to :ride
  belongs_to :user
end

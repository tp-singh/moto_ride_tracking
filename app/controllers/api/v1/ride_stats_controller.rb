module Api
  module V1
    class RideStatsController < ApplicationController
      before_action :set_ride

      def show
        raise AuthenticationError, 'Not a member of this ride' unless member_of_ride?

        locations = RideLocation.where(ride_id: @ride.id)
        active    = locations.where.not(rider_status: 'offline')
                             .where('recorded_at > ?', 10.minutes.ago)

        speeds = active.where('speed > 0').pluck(:speed)
        avg_speed_ms  = speeds.empty? ? nil : speeds.sum / speeds.size
        avg_speed_kmh = avg_speed_ms ? (avg_speed_ms * 3.6).round(1) : nil

        elapsed_secs = @ride.started_at ? (Time.current - @ride.started_at).to_i : nil

        total_riders  = @ride.ride_memberships.active_members.count
        active_riders = active.count

        render json: {
          ride_id:         @ride.id,
          avg_speed_kmh:   avg_speed_kmh,
          elapsed_seconds: elapsed_secs,
          total_riders:    total_riders,
          active_riders:   active_riders
        }
      end

      private

      def set_ride
        id = params[:id]
        @ride = Ride.find_by!(public_id: id) rescue Ride.find(id)
      rescue ActiveRecord::RecordNotFound
        raise NotFoundError
      end

      def member_of_ride?
        @ride.ride_memberships.where(user_id: current_user.id,
                                     status: %w[joined active pending]).exists?
      end
    end
  end
end

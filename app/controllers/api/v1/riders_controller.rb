module Api
  module V1
    class RidersController < ApplicationController
      before_action :set_ride

      def index
        raise AuthenticationError, 'Not a member of this ride' unless member_of_ride?

        memberships = @ride.ride_memberships.active_members.includes(:user, :vehicle)
        redis_locs  = REDIS.hgetall("ride:#{@ride.id}:locations")
                           .transform_values { |v| JSON.parse(v) rescue {} }

        riders = memberships.map do |m|
          loc = redis_locs[m.user_id.to_s]
          {
            user_id:      m.user_id,
            name:         m.user.name,
            username:     m.user.username,
            role:         m.role,
            rider_status: loc&.dig('rider_status') || 'offline',
            latitude:     loc&.dig('latitude')&.to_f,
            longitude:    loc&.dig('longitude')&.to_f,
            speed:        loc&.dig('speed')&.to_f,
            heading:      loc&.dig('heading')&.to_f,
            battery:      loc&.dig('battery')&.to_f,
            last_seen:    loc&.dig('recorded_at')
          }
        end

        render_ok({ riders: riders })
      end

      private

      def set_ride
        id = params[:ride_id]
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

module Api
  module V1
    class RideLocationsController < ApplicationController
      before_action :set_ride

      def create
        batch = params[:locations]
        if batch.present?
          batch.each do |point|
            Locations::IngestLocationService.call(
              ride:    @ride,
              user:    current_user,
              payload: point.permit(:latitude, :longitude, :altitude, :speed,
                                    :heading, :accuracy, :battery_level,
                                    :rider_status, :gps_state, :network_state,
                                    :recorded_at).to_h.symbolize_keys
            )
          end
        else
          Locations::IngestLocationService.call(
            ride:    @ride,
            user:    current_user,
            payload: location_params
          )
        end

        head :no_content
      end

      private

      def set_ride
        id = params[:ride_id]
        @ride = Rails.cache.fetch("ride_by_pub:#{id}", expires_in: 30.seconds) do
          Ride.find_by!(public_id: id) rescue Ride.find(id)
        end
        raise NotFoundError unless @ride
        raise AuthenticationError, 'Not a member of this ride' unless member_of_ride?
        raise AuthenticationError, 'Ride is not active'        unless @ride.live?
      rescue ActiveRecord::RecordNotFound
        raise NotFoundError
      end

      def member_of_ride?
        @ride.ride_memberships.where(user_id: current_user.id, status: %w[joined active]).exists?
      end

      def location_params
        params.permit(:latitude, :longitude, :altitude, :speed, :heading,
                      :accuracy, :battery_level, :rider_status,
                      :gps_state, :network_state, :recorded_at)
      end
    end
  end
end

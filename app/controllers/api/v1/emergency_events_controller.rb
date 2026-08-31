module Api
  module V1
    class EmergencyEventsController < ApplicationController
      before_action :set_ride

      def create
        raise AuthenticationError, 'Not a member of this ride' unless member_of_ride?
        raise AuthenticationError, 'Ride is not active'        unless @ride.live?

        event = Emergencies::TriggerEmergencyService.call(
          ride:   @ride,
          user:   current_user,
          params: emergency_params
        )
        render_created EmergencyEventBlueprint.render_as_hash(event)
      end

      private

      def set_ride
        id = params[:ride_id]
        @ride = Ride.find_by!(public_id: id) rescue Ride.find(id)
      rescue ActiveRecord::RecordNotFound
        raise NotFoundError
      end

      def member_of_ride?
        @ride.ride_memberships.where(user_id: current_user.id, status: %w[joined active]).exists?
      end

      def emergency_params
        params.permit(:event_type, :sub_type, :notes, :latitude, :longitude)
      end
    end
  end
end

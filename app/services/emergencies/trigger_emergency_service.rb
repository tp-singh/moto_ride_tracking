module Emergencies
  class TriggerEmergencyService
    def self.call(ride:, user:, params:)
      lat = params[:latitude].presence&.to_f
      lng = params[:longitude].presence&.to_f

      event = ride.emergency_events.create!(
        user:       user,
        event_type: params[:event_type] || 'sos',
        sub_type:   params[:sub_type],
        notes:      params[:notes],
        latitude:   lat,
        longitude:  lng
      )

      rider_status = case params[:event_type]
                     when 'sos', 'medical' then 'sos'
                     else 'mechanical'
                     end
      RideLocation.find_by(ride_id: ride.id, user_id: user.id)
                  &.update!(rider_status: rider_status)

      ActionCable.server.broadcast("ride_#{ride.id}", {
        type:       'emergency_created',
        user_id:    user.id,
        name:       user.name,
        event_type: event.event_type,
        sub_type:   event.sub_type,
        latitude:   event.latitude,
        longitude:  event.longitude,
        created_at: event.created_at.iso8601
      })

      push_title = event.event_type == 'sos' ? '🚨 SOS Alert' : '⚠️ Rider Alert'
      push_body  = "#{user.name} needs help on ride #{ride.name}"
      PushNotificationJob.perform_later(
        ride_id:    ride.id,
        title:      push_title,
        body:       push_body,
        data:       { type: 'sos_alert', ride_id: ride.public_id,
                      event_type: event.event_type,
                      user_id: user.id.to_s, user_name: user.name,
                      latitude: event.latitude&.to_s, longitude: event.longitude&.to_s },
        exclude_id: user.id
      )

      event
    end
  end
end

class RideChannel < ApplicationCable::Channel
  def subscribed
    ride = Ride.find_by(id: params[:ride_id])

    unless ride && authorized_member?(ride)
      reject
      return
    end

    @ride = ride
    stream_from "ride_#{ride.id}"

    REDIS.setex("ride:#{ride.id}:presence:#{current_user.id}", 120, Time.current.iso8601)

    ActionCable.server.broadcast("ride_#{ride.id}", {
      type:    'rider_connected',
      user_id: current_user.id,
      name:    current_user.name
    })

    transmit({ type: 'ride_snapshot', data: build_snapshot(ride) })
  end

  def unsubscribed
    return unless @ride

    REDIS.del("ride:#{@ride.id}:presence:#{current_user.id}")

    ActionCable.server.broadcast("ride_#{@ride.id}", {
      type:    'rider_disconnected',
      user_id: current_user.id
    })
  end

  def update_status(data)
    return unless @ride&.live?

    status = data['status']
    return unless RideLocation::RIDER_STATUSES.include?(status)

    redis_key     = "ride:#{@ride.id}:locations"
    existing_json = REDIS.hget(redis_key, current_user.id.to_s)
    if existing_json
      existing = JSON.parse(existing_json) rescue {}
      REDIS.hset(redis_key, current_user.id.to_s, existing.merge('rider_status' => status).to_json)
    end

    RideLocation.where(ride_id: @ride.id, user_id: current_user.id)
                .update_all(rider_status: status)

    ActionCable.server.broadcast("ride_#{@ride.id}", {
      type:         'rider_status_changed',
      user_id:      current_user.id,
      rider_status: status,
      updated_at:   Time.current.iso8601
    })
  end

  def ping(_data = nil)
    REDIS.setex("ride:#{@ride.id}:presence:#{current_user.id}", 120, Time.current.iso8601) if @ride
    transmit({ type: 'pong' })
  end

  private

  def authorized_member?(ride)
    ride.ride_memberships.where(user_id: current_user.id, status: %w[joined active pending]).exists?
  end

  def build_snapshot(ride)
    redis_locs  = REDIS.hgetall("ride:#{ride.id}:locations")
                       .transform_values { |v| JSON.parse(v) rescue {} }
    memberships = ride.ride_memberships.active_members.includes(:user).to_a

    {
      ride_id:   ride.id,
      status:    ride.status,
      leader_id: ride.leader_id,
      leader:    { id: ride.leader.id, name: ride.leader.name, username: ride.leader.username },
      riders:    memberships.map do |m|
        loc = redis_locs[m.user_id.to_s]
        {
          user_id:      m.user_id,
          name:         m.user.name,
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
    }
  end
end

module Locations
  class IngestLocationService
    MAX_SPEED_MS  = 100
    MAX_ACCURACY  = 500
    STALE_SECONDS = 300

    LOCATIONS_KEY = ->(ride_id) { "ride:#{ride_id}:locations" }
    LOCATIONS_TTL = 3600

    PING_KEY = ->(ride_id, user_id) { "ride:#{ride_id}:rider:#{user_id}:ping" }
    PING_TTL = 30

    def self.call(ride:, user:, payload:)
      return unless valid?(payload)

      recorded_at = parse_time(payload[:recorded_at])
      redis_key   = LOCATIONS_KEY.call(ride.id)
      ping_key    = PING_KEY.call(ride.id, user.id)

      rider_status = if payload[:rider_status].present?
                       payload[:rider_status]
                     else
                       existing = REDIS.hget(redis_key, user.id.to_s)
                       existing ? (JSON.parse(existing) rescue {})['rider_status'] || 'riding' : 'riding'
                     end

      gps_state     = payload[:gps_state]     || 'good'
      network_state = payload[:network_state] || 'online'
      battery       = payload[:battery_level]&.to_i

      location_blob = {
        user_id:       user.id,
        latitude:      payload[:latitude].to_f,
        longitude:     payload[:longitude].to_f,
        altitude:      payload[:altitude]&.to_f,
        speed:         payload[:speed]&.to_f,
        heading:       payload[:heading]&.to_f,
        accuracy:      payload[:accuracy]&.to_f,
        rider_status:  rider_status,
        gps_state:     gps_state,
        network_state: network_state,
        battery:       battery,
        recorded_at:   recorded_at.iso8601,
        updated_at:    Time.current.iso8601
      }

      REDIS.with do |conn|
        conn.pipelined do |pipe|
          pipe.hset(redis_key, user.id.to_s, location_blob.to_json)
          pipe.expire(redis_key, LOCATIONS_TTL)
          pipe.setex(ping_key, PING_TTL, '1')
        end
      end

      ActionCable.server.broadcast("ride_#{ride.id}", {
        type:         'location_updated',
        user_id:      user.id,
        latitude:     payload[:latitude].to_f,
        longitude:    payload[:longitude].to_f,
        speed:        payload[:speed]&.to_f,
        heading:      payload[:heading]&.to_f,
        altitude:     payload[:altitude]&.to_f,
        rider_status: rider_status,
        battery:      battery,
        gps_state:    gps_state,
        recorded_at:  recorded_at.iso8601
      })

      bucketed_at = recorded_at.change(sec: recorded_at.sec < 30 ? 0 : 30)
      bucket_key  = "track_bucket:#{ride.id}:#{user.id}:#{bucketed_at.to_i}"
      if REDIS.set(bucket_key, 1, nx: true, ex: 35)
        TrackArchiveJob.perform_async(
          ride.id, user.id,
          payload[:latitude].to_f, payload[:longitude].to_f,
          payload[:altitude]&.to_f, payload[:speed]&.to_f,
          payload[:heading]&.to_f, payload[:accuracy]&.to_f,
          recorded_at.iso8601,
          rider_status, battery, gps_state, network_state
        )
      end

      throttle_key = "group_intel_throttle:#{ride.id}"
      GroupIntelligenceJob.perform_async(ride.id) if REDIS.set(throttle_key, 1, nx: true, ex: 3)
    end

    def self.valid?(payload)
      lat = payload[:latitude].to_f
      lng = payload[:longitude].to_f
      return false unless lat.between?(-90, 90) && lng.between?(-180, 180)
      return false if lat == 0.0 && lng == 0.0

      speed = payload[:speed]&.to_f
      return false if speed && speed > MAX_SPEED_MS

      accuracy = payload[:accuracy]&.to_f
      return false if accuracy && accuracy > MAX_ACCURACY

      recorded_at = parse_time(payload[:recorded_at]) rescue nil
      return false unless recorded_at
      return false if recorded_at < STALE_SECONDS.seconds.ago
      return false if recorded_at > 30.seconds.from_now

      true
    end
    private_class_method :valid?

    def self.parse_time(value)
      return Time.current if value.blank?
      Time.parse(value.to_s)
    end
    private_class_method :parse_time
  end
end

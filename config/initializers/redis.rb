REDIS = ConnectionPool::Wrapper.new(size: Integer(ENV.fetch('REDIS_POOL_SIZE', 10)), timeout: 1) do
  Redis::Namespace.new(
    "rider_tracking:#{Rails.env}",
    redis: Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
  )
end

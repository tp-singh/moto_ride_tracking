SIDEKIQ_REDIS_URL = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')

Sidekiq.configure_client do |config|
  config.redis = { url: SIDEKIQ_REDIS_URL, size: 5 }
end

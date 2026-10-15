source "https://rubygems.org"

gem "rails", "~> 8.0.0"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Auth
gem "bcrypt", "~> 3.1"
gem "jwt", "~> 2.7"

# Redis for ActionCable + caching
gem "redis", "~> 5.0"
gem "redis-namespace", "~> 1.11"
gem "connection_pool", "~> 2.4"

# Sidekiq client-only (enqueue jobs to main API's Sidekiq)
gem "sidekiq", "~> 7.0"

# JSON
gem "oj", "~> 3.16"
gem "blueprinter", "~> 1.0"

# Auth / rate limiting
gem "rack-cors"
gem "rack-attack"

# Pagination
gem "kaminari", "~> 1.2"

# Env
gem "dotenv-rails", "~> 3.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.0"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "timecop", "~> 0.9"
  gem "webmock", "~> 3.0"
  gem "rubocop-rails-omakase", require: false
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

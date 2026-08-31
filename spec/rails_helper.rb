require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
ENV['JWT_SECRET'] ||= 'test_secret_for_specs'
require_relative '../config/environment'
require 'rspec/rails'
require 'webmock/rspec'
require 'shoulda/matchers'

RSpec.configure do |config|
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
end

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Stub Redis for unit tests — service specs that need Redis use double explicitly
RSpec.shared_context 'stubbed redis', shared_context: :metadata do
  let(:fake_redis_hash) { {} }
  let(:fake_redis_set)  { {} }

  before do
    allow(REDIS).to receive(:with).and_yield(double('redis',
      hset: nil, hget: nil, expire: nil, setex: nil, set: nil,
      pipelined: nil
    ))
  end
end

class GroupIntelligenceJob
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 0

  def perform(*)
    raise NotImplementedError, 'This job runs in the main API Sidekiq process'
  end
end

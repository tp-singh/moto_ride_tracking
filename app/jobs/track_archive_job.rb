class TrackArchiveJob
  include Sidekiq::Worker
  sidekiq_options queue: 'low', retry: 3

  def perform(*)
    raise NotImplementedError, 'This job runs in the main API Sidekiq process'
  end
end

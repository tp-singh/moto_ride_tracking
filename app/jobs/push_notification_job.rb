class PushNotificationJob < ApplicationJob
  queue_as :critical

  def perform(ride_id:, title:, body:, data: {}, exclude_id: nil)
    raise NotImplementedError, 'This job runs in the main API Sidekiq process'
  end
end

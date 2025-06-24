class CreateDailyAnalyticsSnapshotsJob < ApplicationJob
  queue_as :default

  def perform
    # Process all active subscriptions
    Subscription.find_each do |subscription|
      # Skip if we already have a snapshot for today
      next if subscription.analytics_snapshots.exists?(snapshot_date: Date.current)
      
      # Create snapshot for this subscription
      FetchTikTokDataJob.perform_later(subscription.id)
    end
    
    # Schedule next run for tomorrow
    CreateDailyAnalyticsSnapshotsJob.set(wait: 1.day).perform_later
  end
end

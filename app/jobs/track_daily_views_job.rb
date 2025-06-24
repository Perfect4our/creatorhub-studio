class TrackDailyViewsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Starting daily view tracking for all active subscriptions"
    
    # Get all active subscriptions
    subscriptions = Subscription.active.includes(:user)
    
    Rails.logger.info "Found #{subscriptions.count} active subscriptions to track"
    
    success_count = 0
    error_count = 0
    
    subscriptions.find_each do |subscription|
      begin
        Rails.logger.info "Tracking daily views for subscription #{subscription.id} (#{subscription.platform})"
        
        # Track daily views for this subscription
        subscription.track_daily_views!
        
        success_count += 1
        Rails.logger.info "Successfully tracked views for subscription #{subscription.id}"
        
      rescue => e
        error_count += 1
        Rails.logger.error "Failed to track views for subscription #{subscription.id}: #{e.message}"
        Rails.logger.error "Error details: #{e.backtrace.first(3).join('\n')}"
      end
    end
    
    Rails.logger.info "Daily view tracking completed: #{success_count} successful, #{error_count} errors"
    
    # Return summary
    {
      total_processed: subscriptions.count,
      successful: success_count,
      errors: error_count,
      completed_at: Time.current
    }
  end
end

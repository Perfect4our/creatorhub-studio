class FetchYoutubeDataJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    
    unless subscription
      Rails.logger.error "FetchYoutubeDataJob: Subscription #{subscription_id} not found"
      return
    end
    
    unless subscription.platform == 'youtube'
      Rails.logger.error "FetchYoutubeDataJob: Subscription #{subscription_id} is not a YouTube subscription"
      return
    end
    
    unless subscription.active?
      Rails.logger.info "FetchYoutubeDataJob: Subscription #{subscription_id} is not active, skipping"
      return
    end
    
    Rails.logger.info "FetchYoutubeDataJob: Starting data fetch for subscription #{subscription_id}"
    
    begin
      youtube_service = YoutubeService.new(subscription)
      
      if youtube_service.sync!
        Rails.logger.info "FetchYoutubeDataJob: Successfully fetched data for subscription #{subscription_id}"
        
        # Schedule next update in 1 hour
        FetchYoutubeDataJob.set(wait: 1.hour).perform_later(subscription_id)
      else
        Rails.logger.error "FetchYoutubeDataJob: Failed to sync data for subscription #{subscription_id}"
        
        # Retry in 30 minutes on failure
        FetchYoutubeDataJob.set(wait: 30.minutes).perform_later(subscription_id)
      end
      
    rescue => e
      Rails.logger.error "FetchYoutubeDataJob: Error processing subscription #{subscription_id}: #{e.message}"
      Rails.logger.error "Error details: #{e.backtrace.first(5).join('\n')}"
      
      # Retry in 30 minutes on error
      FetchYoutubeDataJob.set(wait: 30.minutes).perform_later(subscription_id)
    end
  end
end 
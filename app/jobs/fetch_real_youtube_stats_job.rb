class FetchRealYoutubeStatsJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "🔄 Starting daily YouTube stats collection..."
    
    # Find all active YouTube subscriptions
    youtube_subscriptions = Subscription.where(platform: 'youtube', active: true)
    
    if youtube_subscriptions.empty?
      Rails.logger.info "No active YouTube subscriptions found"
      return
    end
    
    youtube_subscriptions.each do |subscription|
      begin
        fetch_stats_for_subscription(subscription)
      rescue => e
        Rails.logger.error "Failed to fetch stats for subscription #{subscription.id}: #{e.message}"
        next
      end
    end
    
    Rails.logger.info "✅ Completed daily YouTube stats collection"
  end
  
  private
  
  def fetch_stats_for_subscription(subscription)
    Rails.logger.info "Fetching stats for channel: #{subscription.channel_id}"
    
    youtube_service = YoutubeService.new(subscription)
    
    # Get current real stats from YouTube API
    current_stats = youtube_service.get_public_stats
    current_views = current_stats[:total_views]
    current_subscribers = current_stats[:total_subscribers]
    current_video_count = current_stats[:video_count]
    
    Rails.logger.info "Current stats - Views: #{current_views}, Subscribers: #{current_subscribers}"
    
    today = Date.current
    
    # Check if we already have today's data
    existing_tracking = subscription.daily_view_trackings.find_by(tracked_date: today)
    if existing_tracking
      Rails.logger.info "Already have data for today, skipping..."
      return
    end
    
    # Get yesterday's tracking to calculate daily gains
    yesterday_tracking = subscription.daily_view_trackings.find_by(tracked_date: today - 1.day)
    
    if yesterday_tracking
      daily_view_gain = current_views - yesterday_tracking.total_views
      daily_subscriber_gain = current_subscribers - yesterday_tracking.total_subscribers
      Rails.logger.info "Daily gains - Views: +#{daily_view_gain}, Subscribers: +#{daily_subscriber_gain}"
    else
      # First day of tracking
      daily_view_gain = nil
      daily_subscriber_gain = nil
      Rails.logger.info "First day of tracking - no gains calculated"
    end
    
    # Create today's tracking entry
    tracking = subscription.daily_view_trackings.create!(
      tracked_date: today,
      total_views: current_views,
      total_subscribers: current_subscribers,
      daily_view_gain: daily_view_gain,
      daily_subscriber_gain: daily_subscriber_gain,
      estimated_revenue: nil,  # No real revenue data available
      video_performance: current_stats[:top_videos] || [],
      platform_metadata: {
        last_updated: Time.current,
        api_source: 'youtube_data_api_v3_public',
        real_data: true,
        video_count: current_video_count,
        job_run: true
      }
    )
    
    Rails.logger.info "✅ Created tracking record for #{today}"
    
    # Update subscription's latest stats for faster dashboard loading
    subscription.update!(
      last_synced_at: Time.current,
      sync_status: 'completed'
    )
    
  rescue => e
    Rails.logger.error "Error fetching stats for subscription #{subscription.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Update subscription with error status
    subscription.update!(
      last_synced_at: Time.current,
      sync_status: 'failed'
    )
    
    raise e
  end
end 
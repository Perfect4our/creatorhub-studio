class LiveStatsBroadcastJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Get all active subscriptions with realtime enabled
    subscriptions = user.subscriptions.active.where(enable_realtime: true)

    # Skip if no realtime-enabled subscriptions
    if subscriptions.empty?
      # Broadcast a notification that realtime is disabled
      begin
        ActionCable.server.broadcast(
          "live_counter_channel_#{user_id}",
          {
            realtime_disabled: true,
            message: "Real-time updates are currently disabled for all platforms.",
            timestamp: Time.current
          }
        )
      rescue => e
        Rails.logger.error "Failed to broadcast realtime disabled notification: #{e.message}"
      end
      return
    end

    # Use the RealTimeStatsService to get cached stats
    stats_service = RealTimeStatsService.new(user)
    stats = stats_service.fetch_stats

    # Calculate combined followers across all platforms with realtime enabled
    combined_followers = 0
    recent_views_48hr = {}
    
    # Get data for the past 48 hours
    start_date = 2.days.ago.to_date
    end_date = Date.current
    chart_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
    
    # Process each subscription with realtime enabled
    subscriptions.each do |subscription|
      # Get latest stats for this platform
      latest_stat = subscription.daily_stats.recent.first
      combined_followers += latest_stat&.followers.to_i
      
      # Get views data for the past 48 hours
      stats = subscription.daily_stats.where(date: start_date..end_date).order(:date)
      platform_views = stats.map { |stat| stat.views || 0 }
      
      # Fill in missing days with zeros
      if platform_views.length < chart_labels.length
        missing_days = chart_labels.length - platform_views.length
        platform_views = [0] * missing_days + platform_views
      end
      
      recent_views_48hr[subscription.platform] = platform_views
    end

    # Broadcast the data to the user's channel
    begin
      ActionCable.server.broadcast(
        "live_counter_channel_#{user_id}",
        {
          combined_followers: combined_followers,
          recent_views_48hr: recent_views_48hr,
          chart_labels: chart_labels,
          timestamp: Time.current,
          realtime_enabled: true,
          realtime_platforms: subscriptions.pluck(:platform)
        }
      )
    rescue => e
      Rails.logger.error "Failed to broadcast stats: #{e.message}"
    end
    
    # Reschedule the job to run again in 10 seconds, but only in production
    # In development with inline processing, this would cause an infinite recursion
    if !Rails.env.development? && user.subscriptions.active.where(enable_realtime: true).exists?
      begin
        self.class.set(wait: 10.seconds).perform_later(user_id)
      rescue => e
        Rails.logger.error "Failed to reschedule stats broadcast job: #{e.message}"
      end
    end
  end
end

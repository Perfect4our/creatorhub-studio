class RealTimeStatsService
  # Cache key constants
  CACHE_NAMESPACE = "real_time_stats"
  CACHE_EXPIRY = 30.seconds # Reduced from 5 minutes to 30 seconds
  
  def initialize(user)
    @user = user
  end
  
  def fetch_stats
    # Try to get from cache first
    cached_stats = Rails.cache.read(cache_key)
    return cached_stats if cached_stats.present?
    
    # If not in cache, calculate and store
    stats = calculate_stats
    Rails.cache.write(cache_key, stats, expires_in: CACHE_EXPIRY)
    
    stats
  end
  
  # Fetch stats specifically for a platform with per-platform caching
  def fetch_platform_stats(platform)
    platform_cache_key = "#{cache_key}:platform:#{platform}"
    
    # Try to get from cache first
    cached_stats = Rails.cache.read(platform_cache_key)
    return cached_stats if cached_stats.present?
    
    # If not in cache, calculate and store
    subscription = @user.subscriptions.active.find_by(platform: platform)
    return nil unless subscription
    
    stats = calculate_platform_stats(subscription)
    Rails.cache.write(platform_cache_key, stats, expires_in: CACHE_EXPIRY)
    
    stats
  end
  
  def broadcast_stats
    # Only broadcast for users with realtime-enabled subscriptions
    return unless @user.subscriptions.active.where(enable_realtime: true).exists?
    
    begin
      LiveStatsBroadcastJob.perform_later(@user.id)
    rescue => e
      Rails.logger.error "Failed to broadcast stats: #{e.message}"
    end
  end
  
  def schedule_periodic_updates
    # Skip scheduling in development to avoid infinite recursion with inline job processing
    return if Rails.env.development?
    
    # Only schedule updates for users with realtime-enabled subscriptions
    return unless @user.subscriptions.active.where(enable_realtime: true).exists?
    
    # Check if we already have a job scheduled
    return if scheduled_job_exists?
    
    # Schedule a job to run every 10 seconds
    begin
      LiveStatsBroadcastJob.set(wait: 10.seconds).perform_later(@user.id)
    rescue => e
      Rails.logger.error "Failed to schedule periodic updates: #{e.message}"
      # Don't raise the error - allow the app to continue without real-time updates
    end
  end
  
  # Check if real-time data is enabled for any platform
  def realtime_enabled?
    @user.subscriptions.active.where(enable_realtime: true).exists?
  end
  
  # Check if real-time data is enabled for a specific platform
  def platform_realtime_enabled?(platform)
    @user.subscriptions.active.where(platform: platform, enable_realtime: true).exists?
  end
  
  # Get platforms with real-time data enabled
  def realtime_enabled_platforms
    @user.subscriptions.active.where(enable_realtime: true).pluck(:platform)
  end
  
  private
  
  def calculate_stats
    # Get all active subscriptions for the user
    subscriptions = @user.subscriptions.active
    
    # Skip if no subscriptions
    return {} if subscriptions.empty?
    
    # Calculate combined followers across all platforms
    combined_followers = 0
    recent_views_48hr = {}
    platform_stats = {}
    
    # Get data for the past 48 hours
    start_date = 2.days.ago.to_date
    end_date = Date.current
    chart_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
    
    # Process each subscription
    subscriptions.each do |subscription|
      # Get latest stats for this platform
      latest_stat = subscription.daily_stats.recent.first
      next unless latest_stat
      
      combined_followers += latest_stat.followers.to_i
      
      platform_stats[subscription.platform] = {
        views: latest_stat.views || 0,
        followers: latest_stat.followers || 0,
        revenue: latest_stat.revenue || 0,
        platform: subscription.platform,
        realtime_enabled: subscription.enable_realtime
      }
      
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
    
    # Calculate totals
    total_views = platform_stats.sum { |_, stats| stats[:views] }
    total_revenue = platform_stats.sum { |_, stats| stats[:revenue] }
    
    {
      combined_followers: combined_followers,
      total_views: total_views,
      total_revenue: total_revenue,
      platform_stats: platform_stats,
      recent_views_48hr: recent_views_48hr,
      chart_labels: chart_labels,
      realtime_enabled: realtime_enabled?
    }
  end
  
  def calculate_platform_stats(subscription)
    return nil unless subscription
    
    # Get latest stats for this platform
    latest_stat = subscription.daily_stats.recent.first
    return nil unless latest_stat
    
    # Get data for the past 48 hours
    start_date = 2.days.ago.to_date
    end_date = Date.current
    chart_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
    
    # Get views data for the past 48 hours
    stats = subscription.daily_stats.where(date: start_date..end_date).order(:date)
    platform_views = stats.map { |stat| stat.views || 0 }
    
    # Fill in missing days with zeros
    if platform_views.length < chart_labels.length
      missing_days = chart_labels.length - platform_views.length
      platform_views = [0] * missing_days + platform_views
    end
    
    {
      views: latest_stat.views || 0,
      followers: latest_stat.followers || 0,
      revenue: latest_stat.revenue || 0,
      platform: subscription.platform,
      realtime_enabled: subscription.enable_realtime,
      recent_views: platform_views,
      chart_labels: chart_labels
    }
  end
  
  def cache_key
    "#{CACHE_NAMESPACE}:user:#{@user.id}"
  end
  
  def scheduled_job_exists?
    # In a real app, you would check a job tracking system or Redis
    # For simplicity, we'll assume no job exists
    false
  end
end

class PagesController < ApplicationController
  before_action :authenticate_user!, except: [:home, :privacy, :terms, :posthog_test, :button_test]
  
  def home
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard
    if user_signed_in?
      load_dashboard_data
    else
      redirect_to new_user_session_path, alert: 'Please sign in to access your dashboard.'
    end
  end

  # AJAX endpoint for loading heavy analytics data
  def load_analytics_data
    return head :unauthorized unless user_signed_in?
    
    @subscriptions = current_user.subscriptions.active
    platform = params[:platform]
    
    if platform.present?
      subscription = @subscriptions.find_by(platform: platform)
      return render json: { error: 'Platform not found' }, status: 404 unless subscription
      
      analytics_data = Rails.cache.fetch("analytics_data_#{current_user.id}_#{platform}", expires_in: 10.minutes) do
        load_platform_analytics(subscription)
      end
      
      render json: analytics_data
    else
      render json: { error: 'Platform parameter required' }, status: 400
    end
  end

  # AJAX endpoint for loading yearly history
  def load_yearly_history
    return head :unauthorized unless user_signed_in?
    
    @subscriptions = current_user.subscriptions.active
    platform = params[:platform]
    
    yearly_data = Rails.cache.fetch("yearly_history_#{current_user.id}_#{platform}", expires_in: 30.minutes) do
      calculate_yearly_history(platform)
    end
    
    render json: yearly_data
  end

  # AJAX endpoint for updating dashboard data when time period changes
  def update_dashboard_data
    return head :unauthorized unless user_signed_in?
    
    @selected_platform = params[:platform]
    @selected_time_window = params[:time_window] || '28'
    
    # Handle custom date range
    if @selected_time_window == 'custom'
      @start_date = Date.parse(params[:start_date]) rescue 30.days.ago.to_date
      @end_date = Date.parse(params[:end_date]) rescue Date.current
    end
    
    @subscriptions = current_user.subscriptions.active.includes(:daily_stats, :daily_view_trackings)
    
    # Filter subscriptions by platform if specified
    if @selected_platform.present?
      @subscriptions = @subscriptions.where(platform: @selected_platform)
    end
    
    # Quick cache for the new data
    cache_key = "dashboard_update_#{current_user.id}_#{@selected_platform}_#{@selected_time_window}_#{@start_date}_#{@end_date}"
    data = Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
      {
        stats: calculate_quick_stats,
        platform_stats: calculate_platform_stats,
        chart_data: calculate_chart_data,
        top_videos: calculate_top_videos,
        summary_title: calculate_summary_title
      }
    end
    
    render json: {
      stats: data[:stats],
      platform_stats: data[:platform_stats],
      chart_data: data[:chart_data][:chart_data],
      chart_labels: data[:chart_data][:chart_labels],
      platform_data: data[:chart_data][:platform_data],
      top_videos: data[:top_videos],
      summary_title: data[:summary_title]
    }
  end

  def privacy
    # Privacy policy page - publicly accessible
  end

  def terms
    # Terms of service page - publicly accessible
  end

  def posthog_test
    # PostHog test page - accessible to signed-in users and visitors
  end

  def button_test
    # Button management test page - accessible to signed-in users and visitors
  end

  private
  
  def load_dashboard_data
    @subscriptions = current_user.subscriptions.active.includes(:daily_stats, :daily_view_trackings)
    @selected_platform = params[:platform]
    @selected_time_window = params[:time_window] || '28'
    @has_permanent_access = current_user.has_permanent_subscription?
    
    # Handle custom date range
    if @selected_time_window == 'custom'
      @start_date = Date.parse(params[:start_date]) rescue 30.days.ago.to_date
      @end_date = Date.parse(params[:end_date]) rescue Date.current
    end
    
    # Filter subscriptions by platform if specified
    if @selected_platform.present?
      @subscriptions = @subscriptions.where(platform: @selected_platform)
    end
    
    if @subscriptions.any? || @has_permanent_access
      # Quick cache check for basic stats (1 minute cache)
      cache_key = "dashboard_quick_stats_#{current_user.id}_#{@selected_platform}_#{@selected_time_window}"
      @stats = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        calculate_quick_stats
      end
      
      # Quick platform stats (30 second cache)
      platform_cache_key = "dashboard_platform_stats_#{current_user.id}_#{@selected_platform}"
      @platform_stats = Rails.cache.fetch(platform_cache_key, expires_in: 30.seconds) do
        calculate_platform_stats
      end
      
      # Chart data (5 minute cache since it's more expensive)
      chart_cache_key = "dashboard_chart_data_#{current_user.id}_#{@selected_platform}_#{@selected_time_window}_#{@start_date}_#{@end_date}"
      cached_chart_data = Rails.cache.fetch(chart_cache_key, expires_in: 5.minutes) do
        calculate_chart_data
      end
      
      @chart_data = cached_chart_data[:chart_data]
      @chart_labels = cached_chart_data[:chart_labels]
      @platform_data = cached_chart_data[:platform_data]
      
      # Videos (2 minute cache)
      videos_cache_key = "dashboard_videos_#{current_user.id}_#{@selected_platform}"
      @platform_videos = Rails.cache.fetch(videos_cache_key, expires_in: 2.minutes) do
        calculate_platform_videos
      end
      
      @videos = @platform_videos['tiktok'] || []
      
      # Initialize analytics data as empty - will be loaded via AJAX if needed
      @analytics_data = {}
      
      # Skip heavy yearly history calculation - will be loaded via AJAX
      @yearly_history = {}
      
    else
      # No subscriptions yet
      @stats = { views: 0, followers: 0, revenue: 0, combined_followers: 0, recent_views_48hr: {}, realtime_enabled: false }
      @platform_stats = {}
      @chart_data = {}
      @chart_labels = []
      @platform_data = {}
      @platform_videos = {}
      @videos = []
      @yearly_history = {}
      @analytics_data = {}
    end
  end
  
  def calculate_quick_stats
    # Calculate stats based on the selected time window
    
    # Determine date range
      case @selected_time_window
      when 'custom'
        start_date = @start_date
        end_date = @end_date
      when '2025'
        start_date = Date.new(2025, 1, 1)
        end_date = [Date.new(2025, 12, 31), Date.current].min
      when '2024'
        start_date = Date.new(2024, 1, 1)
        end_date = Date.new(2024, 12, 31)
      else
        @time_window_days = @selected_time_window.to_i
        start_date = @time_window_days.days.ago.to_date
        end_date = Date.current
      end
      
    if @selected_platform.present?
      subscription = @subscriptions.first
      
      # Get data for the time window
      view_trackings = subscription&.daily_view_trackings
                                  &.where(tracked_date: start_date..end_date)
                                  &.order(:tracked_date)
      
      if view_trackings&.any?
        # Use the latest entry for current totals
        latest_tracking = view_trackings.last
        {
          views: latest_tracking.total_views || 0,
          followers: latest_tracking.total_subscribers || 0,
          revenue: latest_tracking.estimated_revenue&.to_f || 0,
          combined_followers: latest_tracking.total_subscribers || 0,
          recent_views_48hr: {},
          realtime_enabled: subscription&.enable_realtime || false
        }
      else
        # Fall back to daily stats for the time window
        daily_stats = subscription&.daily_stats
                                 &.where(date: start_date..end_date)
                                 &.order(:date)
        
        if daily_stats&.any?
          latest_stat = daily_stats.last
          {
            views: latest_stat.views || 0,
            followers: latest_stat.followers || 0,
            revenue: latest_stat.revenue || 0,
            combined_followers: latest_stat.followers || 0,
            recent_views_48hr: {},
            realtime_enabled: subscription&.enable_realtime || false
          }
        else
          { views: 0, followers: 0, revenue: 0, combined_followers: 0, recent_views_48hr: {}, realtime_enabled: false }
        end
      end
    else
      # Combined stats across all platforms for time window
      total_views = 0
      total_followers = 0
      total_revenue = 0
      any_realtime = false
      
      @subscriptions.find_each do |subscription|
        # Get latest data within time window for each platform
        view_trackings = subscription.daily_view_trackings
                                    .where(tracked_date: start_date..end_date)
                                    .order(:tracked_date)
        
        if view_trackings.any?
          latest_tracking = view_trackings.last
          total_views += latest_tracking.total_views || 0
          total_followers += latest_tracking.total_subscribers || 0
          total_revenue += latest_tracking.estimated_revenue&.to_f || 0
        else
          # Fall back to daily stats
          daily_stats = subscription.daily_stats
                                   .where(date: start_date..end_date)
                                   .order(:date)
          
          if daily_stats.any?
            latest_stat = daily_stats.last
            total_views += latest_stat.views || 0
            total_followers += latest_stat.followers || 0
            total_revenue += latest_stat.revenue || 0
          end
        end
        
        any_realtime ||= subscription.enable_realtime
      end
      
      {
        views: total_views,
        followers: total_followers,
        revenue: total_revenue,
        combined_followers: total_followers,
        recent_views_48hr: {},
        realtime_enabled: any_realtime
      }
    end
  end
  
  def calculate_platform_stats
    platform_stats = {}
    
    @subscriptions.find_each do |subscription|
      platform = subscription.platform
      latest_tracking = subscription.daily_view_trackings.recent.first
      latest_stat = subscription.daily_stats.recent.first
      
      if latest_tracking
        platform_stats[platform] = {
          views: latest_tracking.total_views || 0,
          followers: latest_tracking.total_subscribers || 0,
          revenue: latest_tracking.estimated_revenue&.to_f || 0
        }
      elsif latest_stat
        platform_stats[platform] = {
          views: latest_stat.views || 0,
          followers: latest_stat.followers || 0,
          revenue: latest_stat.revenue || 0
        }
      else
        platform_stats[platform] = { views: 0, followers: 0, revenue: 0 }
      end
    end
    
    platform_stats
  end
  
  def calculate_chart_data
    # Determine date range
    case @selected_time_window
    when 'custom'
      start_date = @start_date
      end_date = @end_date
    when '2025'
      start_date = Date.new(2025, 1, 1)
      end_date = [Date.new(2025, 12, 31), Date.current].min
    when '2024'
      start_date = Date.new(2024, 1, 1)
      end_date = Date.new(2024, 12, 31)
    else
      @time_window_days = @selected_time_window.to_i
      start_date = @time_window_days.days.ago.to_date
      end_date = Date.current
    end
    
    chart_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
    chart_data = {}
    platform_data = {}
    
    @subscriptions.find_each do |subscription|
      platform = subscription.platform
      
      # Use daily view tracking data if available (more efficient single query)
      view_trackings = subscription.daily_view_trackings
                                  .where(tracked_date: start_date..end_date)
                                  .order(:tracked_date)
                                  .pluck(:tracked_date, :daily_view_gain, :daily_subscriber_gain, :estimated_revenue, :total_views, :total_subscribers)
      
      if view_trackings.any?
        # Process the data efficiently
        platform_views = view_trackings.map { |row| row[1] || 0 }
        platform_followers = view_trackings.map { |row| row[2] || 0 }
        platform_revenue = view_trackings.map { |row| row[3]&.to_f || 0 }
        
        # Get totals from last entry
        last_entry = view_trackings.last
        current_views = last_entry[4] || 0
        current_followers = last_entry[5] || 0
        current_revenue = last_entry[3]&.to_f || 0
        
        platform_data[platform] = {
          has_tracking_data: true,
          total_views: current_views,
          total_subscribers: current_followers
              }
            else
        # Fall back to daily stats (single efficient query)
        stats_data = subscription.daily_stats
                                .where(date: start_date..end_date)
                                .order(:date)
                                .pluck(:views, :followers, :revenue)
        
        platform_views = stats_data.map { |row| row[0] || 0 }
        platform_followers = stats_data.map { |row| row[1] || 0 }
        platform_revenue = stats_data.map { |row| row[2] || 0 }
        
        # Get current totals
        latest_stat = stats_data.last
        current_views = latest_stat&.first || 0
        current_followers = latest_stat&.second || 0
        current_revenue = latest_stat&.third || 0
        
        platform_data[platform] = {
          has_tracking_data: false
        }
      end
        
        # Fill in missing days with zeros
      if platform_views.length < chart_labels.length
        missing_days = chart_labels.length - platform_views.length
          platform_views = [0] * missing_days + platform_views
          platform_followers = [0] * missing_days + platform_followers
          platform_revenue = [0] * missing_days + platform_revenue
        end
        
      chart_data[platform] = {
        dates: chart_labels,
            views: platform_views,
            followers: platform_followers,
            revenue: platform_revenue
      }
      
      platform_data[platform].merge!({
        chart_data: chart_data[platform],
          stats: {
            views: current_views,
            followers: current_followers,
            revenue: current_revenue
          }
        })
    end
    
    {
      chart_data: chart_data,
      chart_labels: chart_labels,
      platform_data: platform_data
    }
  end
  
  def calculate_platform_videos
    platform_videos = {}
    
    @subscriptions.find_each do |subscription|
      platform = subscription.platform
      
      case platform
      when 'tiktok'
        platform_videos[platform] = subscription.tik_tok_videos
                                              .order(created_at_tiktok: :desc)
                                              .limit(5)
                                              .to_a
      when 'youtube'
        # For YouTube, use cached data or return empty array
        # Heavy YouTube API calls will be loaded via AJAX
        platform_videos[platform] = []
      else
        platform_videos[platform] = []
      end
    end
    
    platform_videos
  end

  def load_platform_analytics(subscription)
    platform = subscription.platform
    
    case platform
    when 'youtube'
      begin
        youtube_service = YoutubeService.new(subscription)
        
        if youtube_service.analytics_api_available?
          analytics_data = youtube_service.get_analytics_data(30.days.ago, Date.current)
          realtime_data = youtube_service.get_realtime_analytics
          
          {
            demographics: analytics_data[:demographics] || {},
            top_videos: analytics_data[:top_videos] || [],
            realtime: realtime_data || {},
            has_analytics_api: true
          }
        else
          { has_analytics_api: false }
        end
      rescue => e
        Rails.logger.error "Failed to fetch YouTube Analytics data: #{e.message}"
        { has_analytics_api: false, error: e.message }
      end
    else
      { has_analytics_api: false, platform_not_supported: true }
    end
  end
  
  def calculate_yearly_history(platform = nil)
    yearly_history = {}
    
    end_date = Date.current
    start_date = 365.days.ago.to_date
    yearly_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
    
    subscriptions = current_user.subscriptions.active
    subscriptions = subscriptions.where(platform: platform) if platform.present?
    
    subscriptions.find_each do |subscription|
      platform_key = subscription.platform
      
      # Single efficient query for the year
      yearly_stats = subscription.daily_stats
                                .where(date: start_date..end_date)
                                .order(:date)
                                .pluck(:date, :views, :followers, :revenue)
      
      # Create date index mapping for O(1) lookups
      date_indices = {}
      yearly_labels.each_with_index { |date, i| date_indices[date] = i }
      
      # Initialize arrays with nulls
      full_views = Array.new(yearly_labels.length, nil)
      full_followers = Array.new(yearly_labels.length, nil)
      full_revenue = Array.new(yearly_labels.length, nil)
      
      # Fill in data efficiently
      yearly_stats.each do |date, views, followers, revenue|
        date_str = date.strftime('%Y-%m-%d')
        if (index = date_indices[date_str])
          full_views[index] = views || 0
          full_followers[index] = followers || 0
          full_revenue[index] = revenue || 0
        end
      end
      
      yearly_history[platform_key] = {
        labels: yearly_labels,
        views: full_views,
        followers: full_followers,
        revenue: full_revenue
      }
    end
    
    yearly_history
  end

  def acknowledge_subscription_status
    if current_user
      current_user.acknowledge_subscription_status!
      render json: { success: true }
    else
      render json: { success: false, error: 'Not authenticated' }, status: :unauthorized
    end
  end

  def calculate_top_videos
    # Collect all videos from all platforms for the time frame
    all_videos = []
    
    # Get videos from platform_videos (database videos and API videos)
    platform_videos = calculate_platform_videos
    
    platform_videos.each do |platform, videos|
      next unless videos&.any?
      
      videos.each do |video|
        # Handle both database videos and API video objects
        video_data = {
          platform: platform,
          title: (video.respond_to?(:title) ? video.title : video[:title]) || 'Untitled Video',
          video_id: video.respond_to?(:video_id) ? video.video_id : video[:video_id],
          views: (video.respond_to?(:view_count) ? video.view_count : video[:view_count]) || 0,
          likes: (video.respond_to?(:like_count) ? video.like_count : video[:like_count]) || 0,
          comments: (video.respond_to?(:comment_count) ? video.comment_count : video[:comment_count]) || 0,
          thumbnail_url: (video.respond_to?(:thumbnail_url) ? video.thumbnail_url : video[:thumbnail_url]) || nil,
          source: 'platform_data'
        }
        
        # Generate appropriate link
        if video.respond_to?(:id) && video.id.present?
          video_data[:link] = Rails.application.routes.url_helpers.video_path(video)
          video_data[:link_target] = '_self'
        elsif video_data[:video_id].present?
          case platform.downcase
          when 'youtube'
            video_data[:link] = "https://www.youtube.com/watch?v=#{video_data[:video_id]}"
          when 'tiktok'
            video_data[:link] = "https://www.tiktok.com/@username/video/#{video_data[:video_id]}"
          else
            video_data[:link] = "#"
          end
          video_data[:link_target] = '_blank'
        else
          video_data[:link] = "#"
          video_data[:link_target] = '_self'
        end
        
        all_videos << video_data
      end
    end
    
    # Sort by views and get top 5
    all_videos.sort_by { |v| -(v[:views] || 0) }.first(5)
  end

  def calculate_summary_title
    case @selected_time_window.to_s
    when '7'
      "Last 7 Days Summary"
    when '28'
      "Last 28 Days Summary"
    when '90'
      "Last 90 Days Summary"
    when '365'
      "Last 365 Days Summary"
    when '2025'
      "2025 Summary"
    when '2024'
      "2024 Summary"
    when 'custom'
      if @start_date && @end_date
        if @start_date == @end_date
          "#{@start_date.strftime('%B %d, %Y')} Summary"
        elsif @start_date.year == @end_date.year
          if @start_date.month == @end_date.month
            "#{@start_date.strftime('%B %d')} - #{@end_date.strftime('%d, %Y')} Summary"
          else
            "#{@start_date.strftime('%b %d')} - #{@end_date.strftime('%b %d, %Y')} Summary"
          end
        else
          "#{@start_date.strftime('%b %d, %Y')} - #{@end_date.strftime('%b %d, %Y')} Summary"
        end
      else
        "Custom Range Summary"
      end
    else
      "Last #{@selected_time_window} Days Summary"
    end
  end
end

class PagesController < ApplicationController
  before_action :authenticate_user!, except: :home
  
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

  def privacy
    # Privacy policy page
  end

  def terms
    # Terms of service page
  end

  private
  
  def load_dashboard_data
    @subscriptions = current_user.subscriptions.active
    @selected_platform = params[:platform] # Add platform filtering
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
      # Use the RealTimeStatsService to get stats
      stats_service = RealTimeStatsService.new(current_user)
      real_time_stats = stats_service.fetch_stats
      
      # Schedule periodic updates - wrap in begin/rescue to handle Redis unavailability
      begin
        stats_service.schedule_periodic_updates
      rescue => e
        Rails.logger.error "Failed to schedule periodic updates: #{e.message}"
        # Add a flash message to inform the user
        flash.now[:notice] = "Real-time updates are currently disabled. Some features may be limited."
      end
      
      # Set instance variables from the real-time stats
      @platform_stats = real_time_stats[:platform_stats] || {}
      
      # Ensure @platform_stats is populated even if real-time service returns empty data
      if @platform_stats.empty? && @subscriptions.any?
        # Build platform stats from subscriptions
        @subscriptions.each do |subscription|
          platform = subscription.platform
          
          # Get latest tracking data or daily stats
          latest_tracking = subscription.daily_view_trackings.recent.first
          latest_daily_stat = subscription.daily_stats.recent.first
          
          if latest_tracking
            @platform_stats[platform] = {
              views: latest_tracking.total_views,
              followers: latest_tracking.total_subscribers,
              revenue: latest_tracking.estimated_revenue.to_f
            }
          elsif latest_daily_stat
            @platform_stats[platform] = {
              views: latest_daily_stat.views || 0,
              followers: latest_daily_stat.followers || 0,
              revenue: latest_daily_stat.revenue || 0
            }
          else
            # Default values if no data exists
            @platform_stats[platform] = {
              views: 0,
              followers: 0,
              revenue: 0
            }
          end
        end
      end
      
      # Calculate totals (either combined or platform-specific)
      if @selected_platform.present?
        # Show stats for selected platform only
        platform_data = @platform_stats[@selected_platform] || {}
        @stats = {
          views: platform_data[:views] || 0,
          followers: platform_data[:followers] || 0,
          revenue: platform_data[:revenue] || 0,
          realtime_enabled: false # Default to false, will be updated if Redis is available
        }
      else
        # Show combined stats for all platforms
        total_views = @platform_stats.values.sum { |data| data[:views] || 0 }
        total_followers = @platform_stats.values.sum { |data| data[:followers] || 0 }
        total_revenue = @platform_stats.values.sum { |data| data[:revenue] || 0 }
        
        @stats = {
          views: total_views > 0 ? total_views : (real_time_stats[:total_views] || 0),
          followers: total_followers > 0 ? total_followers : (real_time_stats[:combined_followers] || 0),
          revenue: total_revenue > 0 ? total_revenue : (real_time_stats[:total_revenue] || 0),
          realtime_enabled: false # Default to false, will be updated if Redis is available
        }
      end
      
      # Add additional data for real-time updates
      if @selected_platform.present?
        platform_data = @platform_stats[@selected_platform] || {}
        @stats[:combined_followers] = platform_data[:followers] || 0
        @stats[:recent_views_48hr] = platform_data[:recent_views_48hr] || {}
      else
        @stats[:combined_followers] = real_time_stats[:combined_followers] || 0
        @stats[:recent_views_48hr] = real_time_stats[:recent_views_48hr] || {}
      end
      
      # Check if real-time is enabled
      begin
        @stats[:realtime_enabled] = stats_service.realtime_enabled?
      rescue => e
        Rails.logger.error "Failed to check if real-time is enabled: #{e.message}"
        @stats[:realtime_enabled] = false
      end
      
      # Get data for charts based on time window
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
      
      @chart_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
      
      # Prepare platform-specific data for tabs
      @platform_data = {}
      @platform_videos = {}
      @analytics_data = {} # Store enhanced analytics data
      
      @subscriptions.each do |subscription|
        platform = subscription.platform
        
        # Use daily view tracking data if available, otherwise fall back to daily stats
        view_trackings = subscription.daily_view_trackings.for_date_range(start_date, end_date).order(:tracked_date)
        
        if view_trackings.any?
          # Use daily gains for charts (only if we have real data)
          platform_views = view_trackings.map { |t| t.daily_view_gain || 0 }
          platform_followers = view_trackings.map { |t| t.daily_subscriber_gain || 0 }
          platform_revenue = view_trackings.map { |t| t.estimated_revenue&.to_f || 0 }
          
          # Check if we have enough real data for meaningful charts
          real_view_gains = view_trackings.count { |t| t.daily_view_gain.present? }
          real_subscriber_gains = view_trackings.count { |t| t.daily_subscriber_gain.present? }
          
          # Store additional data for enhanced charts
          @platform_data[platform] ||= {}
          @platform_data[platform][:daily_gains] = view_trackings.map(&:daily_view_gain)
          @platform_data[platform][:subscriber_gains] = view_trackings.map(&:daily_subscriber_gain)
          @platform_data[platform][:total_views] = view_trackings.last&.total_views || 0
          @platform_data[platform][:total_subscribers] = view_trackings.last&.total_subscribers || 0
          @platform_data[platform][:has_tracking_data] = true
          @platform_data[platform][:has_enough_data] = real_view_gains >= 2  # Need at least 2 days for trends
          @platform_data[platform][:real_data_points] = real_view_gains
        else
          # Fall back to daily stats
          stats = subscription.daily_stats.where(date: start_date..end_date).order(:date)
          platform_views = stats.map { |stat| stat.views || 0 }
          platform_followers = stats.map { |stat| stat.followers || 0 }
          platform_revenue = stats.map { |stat| stat.revenue || 0 }
          
          @platform_data[platform] ||= {}
          @platform_data[platform][:has_tracking_data] = false
        end
        
        # Enhanced Analytics API data for YouTube
        if platform == 'youtube'
          begin
            youtube_service = YoutubeService.new(subscription)
            
            if youtube_service.analytics_api_available?
              # Get enhanced analytics data
              analytics_data = youtube_service.get_analytics_data(start_date, end_date)
              realtime_data = youtube_service.get_realtime_analytics
              
              # Override with more accurate Analytics API data
              if analytics_data[:views_data]&.any?
                platform_views = analytics_data[:views_data].map { |data| data[:views] || 0 }
              end
              
              if analytics_data[:subscriber_data]&.any?
                # Use net subscriber changes for more accurate follower tracking
                platform_followers = analytics_data[:subscriber_data].map { |data| data[:net_subscribers] || 0 }
              end
              
              if analytics_data[:revenue_data]&.any?
                # Use actual revenue data from Analytics API
                platform_revenue = analytics_data[:revenue_data].map { |data| data[:estimated_revenue] || 0 }
              end
              
              # Store enhanced analytics data
              @analytics_data[platform] = {
                demographics: analytics_data[:demographics] || {},
                top_videos: analytics_data[:top_videos] || [],
                realtime: realtime_data || {},
                has_analytics_api: true
              }
            else
              @analytics_data[platform] = { has_analytics_api: false }
            end
          rescue => e
            Rails.logger.error "Failed to fetch YouTube Analytics data: #{e.message}"
            @analytics_data[platform] = { has_analytics_api: false, error: e.message }
          end
        end
        
        # Fill in missing days with zeros
        if platform_views.length < @chart_labels.length
          missing_days = @chart_labels.length - platform_views.length
          platform_views = [0] * missing_days + platform_views
          platform_followers = [0] * missing_days + platform_followers
          platform_revenue = [0] * missing_days + platform_revenue
        end
        
        # Get the latest stats for this platform
        if @platform_data[platform][:has_tracking_data]
          # Use the totals from daily view tracking (more accurate)
          current_views = @platform_data[platform][:total_views]
          current_followers = @platform_data[platform][:total_subscribers]
          current_revenue = view_trackings.last&.estimated_revenue&.to_f || 0
        else
          # Fall back to daily stats
          latest_stat = subscription.daily_stats.recent.first
          current_views = latest_stat&.views || 0
          current_followers = latest_stat&.followers || 0
          current_revenue = latest_stat&.revenue || 0
        end
        
        # Store platform-specific data
        @platform_data[platform].merge!({
          chart_data: {
            dates: @chart_labels,
            views: platform_views,
            followers: platform_followers,
            revenue: platform_revenue
          },
          stats: {
            views: current_views,
            followers: current_followers,
            revenue: current_revenue
          }
        })
        
        # Get videos for this platform
        if platform == 'tiktok'
          @platform_videos[platform] = TikTokVideo.where(subscription_id: subscription.id)
                                                 .order(created_at_tiktok: :desc)
                                                 .limit(5)
        elsif platform == 'youtube'
          # Get YouTube videos (enhanced with Analytics API if available)
          begin
            youtube_service = YoutubeService.new(subscription)
            youtube_videos = youtube_service.get_videos(10)
            
            @platform_videos[platform] = youtube_videos.map do |video|
              # Convert to a format similar to TikTokVideo for consistency
              views = video[:view_count] || 0
              likes = video[:like_count] || 0
              comments = video[:comment_count] || 0
              
              # Calculate engagement rate for YouTube videos
              engagement_rate = views > 0 ? ((likes + comments).to_f / views * 100).round(1) : 0
              
              {
                video_id: video[:video_id],
                title: video[:title],
                description: video[:description],
                view_count: views,
                like_count: likes,
                comment_count: comments,
                created_at_tiktok: video[:published_at],
                thumbnail_url: video[:thumbnail_url],
                platform: 'youtube',
                engagement_rate: engagement_rate
              }
            end
          rescue => e
            Rails.logger.error "Failed to fetch YouTube videos: #{e.message}"
            @platform_videos[platform] = []
          end
        else
          # For other platforms, we'll use an empty array for now
          @platform_videos[platform] = []
        end
      end
      
      # Calculate combined stats and growth for summary cards
      total_views = @platform_data.values.sum { |data| data[:stats][:views] }
      total_followers = @platform_data.values.sum { |data| data[:stats][:followers] }
      total_revenue = @platform_data.values.sum { |data| data[:stats][:revenue] }
      
      # Calculate growth percentages ONLY from real data
      total_recent_view_gains = @platform_data.values.sum do |data|
        if data[:has_tracking_data] && data[:has_enough_data] && data[:daily_gains]&.any?
          # Only sum gains that are actually present (not nil)
          real_gains = data[:daily_gains].compact.last(7)
          real_gains.sum
        else
          0
        end
      end
      
      total_previous_view_gains = @platform_data.values.sum do |data|
        if data[:has_tracking_data] && data[:has_enough_data] && data[:daily_gains]&.length >= 14
          # Only sum gains that are actually present (not nil)
          all_real_gains = data[:daily_gains].compact
          if all_real_gains.length >= 14
            all_real_gains[-14..-8].sum
          else
            0
          end
        else
          0
        end
      end
      
      # Calculate growth percentages (only if we have enough real data)
      views_growth = if total_previous_view_gains > 0 && total_recent_view_gains > 0
        ((total_recent_view_gains - total_previous_view_gains).to_f / total_previous_view_gains * 100).round(1)
      else
        nil  # Not enough data - will show "Coming Soon"
      end
      
      # Similar calculation for followers (only real data)
      total_recent_follower_gains = @platform_data.values.sum do |data|
        if data[:has_tracking_data] && data[:has_enough_data] && data[:subscriber_gains]&.any?
          real_gains = data[:subscriber_gains].compact.last(7)
          real_gains.sum
        else
          0
        end
      end
      
      total_previous_follower_gains = @platform_data.values.sum do |data|
        if data[:has_tracking_data] && data[:has_enough_data] && data[:subscriber_gains]&.length >= 14
          all_real_gains = data[:subscriber_gains].compact
          if all_real_gains.length >= 14
            all_real_gains[-14..-8].sum
          else
            0
          end
        else
          0
        end
      end
      
      followers_growth = if total_previous_follower_gains > 0 && total_recent_follower_gains > 0
        ((total_recent_follower_gains - total_previous_follower_gains).to_f / total_previous_follower_gains * 100).round(1)
      else
        nil  # Not enough data - will show "Coming Soon"
      end
      
      # Revenue growth - no real data available yet
      revenue_growth = nil  # Will show "Coming Soon"
      
      # Update @stats with accurate totals and growth
      @stats = {
        views: total_views,
        followers: total_followers,
        revenue: total_revenue,
        views_growth: views_growth,
        followers_growth: followers_growth,
        revenue_growth: revenue_growth,
        combined_followers: total_followers,
        recent_views_48hr: {},
        realtime_enabled: @stats&.dig(:realtime_enabled) || false
      }
      
      # For backwards compatibility and dashboard view
      @chart_data = @platform_data.transform_values { |data| data[:chart_data] }
      @platform_stats = @platform_data.transform_values { |data| data[:stats] }
      @videos = @platform_videos['tiktok'] || []
      
      # Get 365-day history for all platforms
      prepare_yearly_history
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
    end
  end
  
  private
  
  def prepare_yearly_history
    @yearly_history = {}
    
    # Calculate start and end dates for 365-day history
    end_date = Date.current
    start_date = 365.days.ago.to_date
    yearly_labels = (start_date..end_date).map { |date| date.strftime('%Y-%m-%d') }
    
    @subscriptions.each do |subscription|
      platform = subscription.platform
      
      # Get stats for this platform for the past 365 days
      yearly_stats = subscription.daily_stats.where(date: start_date..end_date).order(:date)
      
      # Prepare data arrays
      dates = yearly_stats.map { |stat| stat.date.strftime('%Y-%m-%d') }
      views = yearly_stats.map { |stat| stat.views || 0 }
      followers = yearly_stats.map { |stat| stat.followers || 0 }
      revenue = yearly_stats.map { |stat| stat.revenue || 0 }
      
      # Create a mapping of dates to indices for faster lookups
      date_indices = {}
      yearly_labels.each_with_index { |date, i| date_indices[date] = i }
      
      # Initialize arrays with nulls for all dates
      full_views = Array.new(yearly_labels.length, nil)
      full_followers = Array.new(yearly_labels.length, nil)
      full_revenue = Array.new(yearly_labels.length, nil)
      
      # Fill in the data we have
      dates.each_with_index do |date, i|
        if date_indices[date]
          full_views[date_indices[date]] = views[i]
          full_followers[date_indices[date]] = followers[i]
          full_revenue[date_indices[date]] = revenue[i]
        end
      end
      
      @yearly_history[platform] = {
        labels: yearly_labels,
        views: full_views,
        followers: full_followers,
        revenue: full_revenue
      }
    end
  end
end

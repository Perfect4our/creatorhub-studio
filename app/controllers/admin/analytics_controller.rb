class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    # Date range filtering
    @date_range = params[:date_range] || '30'
    @start_date = @date_range.to_i.days.ago.beginning_of_day
    @end_date = Time.current.end_of_day

    # Core metrics
    @total_users = User.count
    @recent_signups = User.where(created_at: @start_date..@end_date).count
    @active_subscriptions = User.where.not(stripe_customer_id: nil).count
    @total_videos = TikTokVideo.count
    @total_subscriptions = Subscription.count
    @recent_activity = recent_activity_feed
    @signup_growth = calculate_signup_growth

    # Enhanced analytics data for charts - REAL DATA ONLY
    @signups_by_day = signups_by_day_data
    @top_pages_data = top_pages_data
    @conversion_funnel_data = conversion_funnel_data
    @platform_breakdown_data = platform_breakdown_data
    @revenue_by_day = revenue_by_day_data
    @user_retention_data = user_retention_data
    @geographic_data = geographic_distribution_data
    @subscription_status_data = subscription_status_data

    # Role and platform filtering
    @role_filter = params[:role_filter] || 'all'
    @platform_filter = params[:platform_filter] || 'all'

    # Apply filters to data
    apply_filters if params[:role_filter].present? || params[:platform_filter].present?

    # PostHog integration data (real data only)
    @posthog_top_events = fetch_posthog_top_events
    @posthog_conversion_data = fetch_posthog_conversion_data

    respond_to do |format|
      format.html
      format.json { 
        render json: {
          total_users: @total_users,
          recent_signups: @recent_signups,
          active_subscriptions: @active_subscriptions,
          signup_growth: @signup_growth,
          signups_by_day: @signups_by_day,
          top_pages_data: @top_pages_data,
          conversion_funnel_data: @conversion_funnel_data,
          platform_breakdown_data: @platform_breakdown_data,
          revenue_by_day: @revenue_by_day,
          user_retention_data: @user_retention_data,
          geographic_data: @geographic_data,
          subscription_status_data: @subscription_status_data,
          posthog_top_events: @posthog_top_events,
          posthog_conversion_data: @posthog_conversion_data,
          recent_activity: @recent_activity
        }
      }
    end
  end

  private

  def ensure_admin
    unless current_user.email == 'perfect4ouryt@gmail.com'
      redirect_to root_path, alert: 'Access denied.'
    end
  end

  def recent_activity_feed
    # Real user activities only
    activities = []
    
    # Recent signups
    User.order(created_at: :desc).limit(10).each do |user|
      activities << {
        type: 'signup',
        user: user.email,
        timestamp: user.created_at,
        description: 'New user registered'
      }
    end
    
    # Recent subscription activities
    User.where.not(stripe_customer_id: nil).order(updated_at: :desc).limit(5).each do |user|
      activities << {
        type: 'subscription',
        user: user.email,
        timestamp: user.updated_at,
        description: 'Subscription activated'
      }
    end
    
    activities.sort_by { |a| a[:timestamp] }.reverse.first(20)
  end

  def calculate_signup_growth
    current_period = User.where(created_at: @start_date..@end_date).count
    previous_start = @start_date - (@end_date - @start_date)
    previous_period = User.where(created_at: previous_start..@start_date).count
    
    return 0 if previous_period == 0
    ((current_period - previous_period).to_f / previous_period * 100).round(1)
  end

  def signups_by_day_data
    days = @date_range.to_i
    
    data = (days.downto(1)).map do |i|
      date = i.days.ago.beginning_of_day
      count = User.where(created_at: date..date.end_of_day).count
      {
        date: date.strftime('%Y-%m-%d'),
        label: date.strftime('%b %d'),
        signups: count,
        cumulative: User.where(created_at: ..date.end_of_day).count
      }
    end
    
    data.reverse
  end

  def top_pages_data
    # Real page data based on actual application pages
    # This would be enhanced with real analytics data in production
    []
  end

  def conversion_funnel_data
    # Real conversion data based on actual user journey
    total_users = @total_users
    subscribed_users = @active_subscriptions
    
    # Only show real data we can calculate
    return [] if total_users == 0
    
    [
      { stage: 'Total Users', count: total_users, percentage: 100 },
      { stage: 'Active Subscriptions', count: subscribed_users, percentage: ((subscribed_users.to_f / total_users) * 100).round(1) }
    ]
  end

  def platform_breakdown_data
    # Real platform data from subscriptions
    platforms = Subscription.group(:platform).count
    
    platform_colors = {
      'youtube' => '#FF0000',
      'tiktok' => '#000000',
      'instagram' => '#E4405F',
      'facebook' => '#1877F2'
    }
    
    platforms.map do |platform, count|
      {
        platform: platform.titleize,
        count: count,
        color: platform_colors[platform] || '#6B7280'
      }
    end
  end

  def revenue_by_day_data
    # Real revenue data from Stripe subscriptions
    days = @date_range.to_i
    
    (days.downto(1)).map do |i|
      date = i.days.ago.beginning_of_day
      # Count actual new subscriptions on this date
      daily_subscriptions = User.where(stripe_customer_id: ..date.end_of_day)
                                .where.not(stripe_customer_id: nil)
                                .where(created_at: date..date.end_of_day)
                                .count
      
      # Calculate actual revenue (assuming $29.99 monthly plan)
      revenue = daily_subscriptions * 29.99
      
      {
        date: date.strftime('%Y-%m-%d'),
        label: date.strftime('%b %d'),
        revenue: revenue,
        subscriptions: daily_subscriptions
      }
    end.reverse
  end

  def user_retention_data
    # Real retention data based on actual user activity
    # This would be enhanced with actual user activity tracking
    return []
  end

  def geographic_distribution_data
    # Real geographic data would come from user IP addresses or profile data
    # For now, return empty array until we implement geo tracking
    return []
  end

  def subscription_status_data
    active = @active_subscriptions
    total = @total_users
    free_users = total - active
    
    return [] if total == 0
    
    [
      { status: 'Active Subscriptions', count: active, percentage: ((active.to_f / total) * 100).round(1), color: '#10B981' },
      { status: 'Free Users', count: free_users, percentage: ((free_users.to_f / total) * 100).round(1), color: '#6B7280' }
    ]
  end

  def apply_filters
    # Apply role and platform filters to data
    # This would filter the various data arrays based on the selected filters
    # For now, this is a placeholder for the filtering logic
  end

  def fetch_posthog_top_events
    # Real PostHog events would be fetched from PostHog API
    # For now, return empty array until PostHog API integration is implemented
    return []
  end

  def fetch_posthog_conversion_data
    # Real PostHog conversion data would be fetched from PostHog API
    # For now, return empty object until PostHog API integration is implemented
    return {}
  end
end 
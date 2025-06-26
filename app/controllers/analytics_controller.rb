class AnalyticsController < ApplicationController
  before_action :authenticate_user!, except: [:track_event]
  skip_before_action :verify_authenticity_token, only: [:track_event]
  
  def index
    redirect_to dashboard_path
  end

  def demographics
    begin
      @subscriptions = current_user.subscriptions.active
      @selected_platform = params[:platform] || 'all'
      
      # Get available platforms for the user
      @available_platforms = @subscriptions.pluck(:platform).uniq
    rescue => e
      Rails.logger.error "Demographics error: #{e.message}"
      @subscriptions = Subscription.none
      @available_platforms = []
      @selected_platform = 'all'
    end
    
    if @subscriptions.any?
      @platform_analytics = {}
      
      @subscriptions.each do |subscription|
        platform = subscription.platform
        
        # Try to get real analytics data
        begin
          case platform
          when 'youtube'
            youtube_service = YoutubeService.new(subscription)
            if youtube_service.analytics_api_available?
              # Get real YouTube Analytics demographics
              analytics_data = youtube_service.get_analytics_data(30.days.ago, Date.current)
              @platform_analytics[platform] = {
                has_real_data: true,
                demographics: analytics_data[:demographics] || {},
                error: nil
              }
            else
              @platform_analytics[platform] = {
                has_real_data: false,
                error: 'Analytics API not available. Enable YouTube Analytics API for detailed demographics.',
                placeholder: true
              }
            end
          when 'tiktok'
            # TikTok doesn't provide demographics through basic API
            @platform_analytics[platform] = {
              has_real_data: false,
              error: 'TikTok demographics require business account and approved API access.',
              placeholder: true
            }
          else
            @platform_analytics[platform] = {
              has_real_data: false,
              error: 'Analytics coming soon for this platform.',
              placeholder: true
            }
          end
        rescue => e
          Rails.logger.error "Error fetching analytics for #{platform}: #{e.message}"
          @platform_analytics[platform] = {
            has_real_data: false,
            error: "Unable to fetch data: #{e.message}",
            placeholder: true
          }
        end
      end
      
      # Set default mock data for display purposes
      @mock_demographics = {
        age: {
          '13-17': 5,
          '18-24': 35,
          '25-34': 25,
          '35-44': 20,
          '45-54': 10,
          '55+': 5
        },
        gender: {
          female: 65,
          male: 30,
          other: 5
        },
        location: {
          USA: 40,
          UK: 15,
          Canada: 10,
          Australia: 8,
          Germany: 7,
          Other: 20
        },
        devices: {
          mobile: 85,
          tablet: 12,
          desktop: 3
        }
      }
    else
      @platform_analytics = {}
      @mock_demographics = {}
    end
  rescue => e
    Rails.logger.error "Demographics controller error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @subscriptions = Subscription.none
    @available_platforms = []
    @platform_analytics = {}
    @mock_demographics = {}
    @selected_platform = 'all'
  end
  
  def comparison
    @subscription = current_user.subscriptions.first
    
    if @subscription
      # In a real application, this data would come from the TikTok API and competitor analysis
      @comparison_data = {
        views: {
          you: 481840,
          average: 350000
        },
        followers: {
          you: 67939,
          average: 50000
        },
        engagement: {
          you: 8.2,
          average: 5.5
        },
        growth: {
          you: 12.5,
          average: 8.0
        }
      }
    end
  end

  # Simple analytics tracking endpoint to avoid CORS issues
  def track_event
    begin
      # Safely extract parameters
      event_name = params[:event].to_s
      properties = params[:properties].is_a?(Hash) ? params[:properties] : {}
      
      event_data = {
        event: event_name,
        properties: properties,
        user_id: current_user&.id,
        session_id: session.id.public_id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        timestamp: Time.current
      }
      
      # Track user activity for real-time "online now" counter
      if current_user
        track_user_activity(current_user.id)
      end
      
      # Log the event (in production you might send to a proper analytics service)
      Rails.logger.info "📊 Analytics Event: #{event_data.to_json}"
      
      # In production, you could:
      # - Store in database for your own analytics
      # - Send to a different analytics service
      # - Forward to PostHog via server-side API (no CORS issues)
      
      head :ok
    rescue => e
      Rails.logger.error "Analytics tracking error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      head :ok # Always return OK to not break frontend
    end
  end

  # Manage PostHog recordings for a user
  def manage_recordings
    return head :unauthorized unless user_signed_in?

    user_id = params[:user_id]
    
    # Validate that the user can only manage their own recordings (unless admin)
    unless current_user.admin? || current_user.id.to_s == user_id.to_s
      return head :forbidden
    end

    begin
      # Schedule the recording management job
      ManagePosthogRecordingsJob.schedule_for_user(user_id: user_id)

      # Track the management request
      PosthogService.track_recording_event(
        user_id: user_id,
        event_type: 'management_requested',
        recording_data: {
          requested_by: current_user.id,
          trigger: 'homepage_visit'
        }
      )

      Rails.logger.info "🎥 PostHog recording management scheduled for user #{user_id}"

      render json: { 
        status: 'success', 
        message: 'Recording management scheduled',
        user_id: user_id
      }
    rescue => e
      Rails.logger.error "Failed to schedule recording management for user #{user_id}: #{e.message}"
      render json: { 
        status: 'error', 
        message: 'Failed to schedule recording management' 
      }, status: :internal_server_error
    end
  end

  private

  def track_user_activity(user_id)
    # Update the real-time active users cache
    begin
      cache_key = "active_users"
      active_users = Rails.cache.read(cache_key) || {}
      
      # Add/update user with current timestamp
      active_users[user_id] = Time.current
      
      # Clean up users who haven't been active in the last 5 minutes
      cutoff_time = 5.minutes.ago
      active_users = active_users.select { |id, timestamp| timestamp > cutoff_time }
      
      # Store back in cache with 6 minute expiry
      Rails.cache.write(cache_key, active_users, expires_in: 6.minutes)
    rescue => e
      Rails.logger.error "Track user activity error: #{e.message}"
      # Don't raise error - just log and continue
    end
  end
end

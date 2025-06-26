class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:destroy]
  
  def index
    @subscriptions = current_user.subscriptions.all
  end

  def new
    @subscription = current_user.subscriptions.new
    
    # In a real app, this would redirect to OAuth providers
    # For now, we'll just show a mock form
  end

  def create
    # Handle both regular form submissions and OAuth callbacks
    if params[:subscription].present?
      # Regular form submission
      @subscription = current_user.subscriptions.new(subscription_params)
      
      if @subscription.save
        # Start the background job to fetch data based on platform
        case @subscription.platform
        when 'tiktok'
          FetchTikTokDataJob.perform_later(@subscription.id)
        when 'youtube'
          FetchYoutubeDataJob.perform_later(@subscription.id)
        end
        
        redirect_to dashboard_path, notice: "#{@subscription.platform.capitalize} account successfully connected."
      else
        render :new, status: :unprocessable_entity
      end
    else
      # OAuth callback - determine platform and redirect
      platform = params[:platform] || 'tiktok'
      case platform
      when 'tiktok'
        tiktok_callback
      when 'youtube'
        youtube_oauth_start
      else
        redirect_to subscriptions_path, alert: "Unsupported platform: #{platform}"
      end
    end
  end
  
  def youtube_oauth_start
    # Start YouTube OAuth flow - redirect to Google
    begin
      youtube_service = YoutubeService.new
      
      # Debug: Check if we have proper credentials
      Rails.logger.info "YouTube OAuth Start - Client ID present: #{ENV['YOUTUBE_CLIENT_ID'].present?}"
      
      unless ENV['YOUTUBE_CLIENT_ID'].present?
        Rails.logger.error "YouTube OAuth Error: Missing YOUTUBE_CLIENT_ID environment variable"
        redirect_to subscriptions_path, alert: "YouTube integration is not properly configured. Please contact support."
        return
      end
      
      redirect_uri = request.base_url + auth_youtube_callback_path
      Rails.logger.info "YouTube OAuth Start - Redirect URI: #{redirect_uri}"
      
      # Check if Analytics API is requested
      analytics_enabled = params[:analytics] == 'true'
      oauth_url = youtube_service.oauth_url(redirect_uri, analytics_enabled)
      
      Rails.logger.info "YouTube OAuth Start - Generated OAuth URL: #{oauth_url}"
      redirect_to oauth_url, allow_other_host: true
    rescue => e
      Rails.logger.error "YouTube OAuth start error: #{e.message}"
      Rails.logger.error "YouTube OAuth start backtrace: #{e.backtrace.first(5).join('\n')}"
      redirect_to subscriptions_path, alert: "Failed to start YouTube authentication: #{e.message}. Please try again."
    end
  end
  
  def youtube_callback
    # Handle YouTube OAuth callback (when user returns from Google)
    begin
      youtube_service = YoutubeService.new
      
      # Debug: Check if we have proper credentials
      Rails.logger.info "YouTube OAuth Callback - Client ID present: #{ENV['YOUTUBE_CLIENT_ID'].present?}"
      Rails.logger.info "YouTube OAuth Callback - Client Secret present: #{ENV['YOUTUBE_CLIENT_SECRET'].present?}"
      Rails.logger.info "YouTube OAuth Callback - API Key present: #{ENV['YOUTUBE_API_KEY'].present?}"
      Rails.logger.info "YouTube OAuth Callback - Code parameter: #{params[:code].present?}"
      
      if params[:code].present?
        # User authorized and Google sent back auth code
        redirect_uri = request.base_url + auth_youtube_callback_path
        Rails.logger.info "YouTube OAuth Callback - Redirect URI: #{redirect_uri}"
        
        token_data = youtube_service.exchange_code_for_token(params[:code], redirect_uri)
        Rails.logger.info "YouTube OAuth Callback - Token exchange successful"
        
        # Get channel information
        channel_info = youtube_service.get_channel_info(token_data['access_token'])
        Rails.logger.info "YouTube OAuth Callback - Channel info: #{channel_info.inspect}"
        
        # Check if we already have this YouTube account
        existing = current_user.subscriptions.find_by(platform: 'youtube', channel_id: channel_info[:channel_id])
        
        # Determine if Analytics API is available based on granted scopes
        has_analytics_scope = token_data['scope']&.include?('yt-analytics.readonly') || false
        
        if existing
          # Update the existing subscription
          existing.update!(
            auth_token: token_data['access_token'],
            refresh_token: token_data['refresh_token'],
            expires_at: Time.current + token_data['expires_in'].seconds,
            scope: token_data['scope'],
            active: true
          )
          
          # Refresh YouTube data
          FetchYoutubeDataJob.perform_later(existing.id)
          
          message = "YouTube account reconnected successfully."
          message += " Analytics API enabled!" if has_analytics_scope
          redirect_to dashboard_path, notice: message
        else
          # Create a new subscription
          subscription = current_user.subscriptions.create!(
            tiktok_uid: channel_info[:channel_id], # Using this field for all platform IDs
            channel_id: channel_info[:channel_id],
            account_name: channel_info[:title],
            account_username: channel_info[:title],
            auth_token: token_data['access_token'],
            refresh_token: token_data['refresh_token'],
            expires_at: Time.current + token_data['expires_in'].seconds,
            scope: token_data['scope'],
            platform: 'youtube',
            active: true,
            enable_realtime: true
          )
          
          # Track platform connection server-side (critical event)
          PosthogService.track_platform_connection(
            user: current_user,
            platform: 'youtube',
            connection_type: has_analytics_scope ? 'analytics_api' : 'basic',
            success: true
          )
          
          # Create initial analytics snapshot to avoid validation errors
          create_initial_snapshot(subscription)
          
          # Start fetching YouTube data
          FetchYoutubeDataJob.perform_later(subscription.id)
          
          message = "YouTube account connected successfully."
          message += " Analytics API enabled!" if has_analytics_scope
          redirect_to dashboard_path, notice: message
        end
      else
        # No code parameter - this shouldn't happen in callback, but handle gracefully
        Rails.logger.error "YouTube OAuth Callback - No authorization code received"
        redirect_to subscriptions_path, alert: "YouTube authorization was not completed. Please try again."
      end
    rescue => e
      Rails.logger.error "YouTube callback error: #{e.message}"
      Rails.logger.error "YouTube callback backtrace: #{e.backtrace.first(5).join('\n')}"
      redirect_to subscriptions_path, alert: "Failed to connect YouTube account: #{e.message}. Please try again."
    end
  end
  
  def tiktok_callback
    # Handle TikTok OAuth callback
    begin
      # Mock TikTok API response
      mock_response = {
        access_token: "mock_access_token_#{Time.now.to_i}",
        refresh_token: "mock_refresh_token_#{Time.now.to_i}",
        expires_in: 86400, # 24 hours
        scope: "user.info.basic,video.list",
        open_id: "tiktok_#{current_user.id}_#{Time.now.to_i}"
      }
      
      # Check if we already have this TikTok account
      existing = current_user.subscriptions.find_by(platform: 'tiktok', channel_id: mock_response[:open_id])
      
      if existing
        # Update the existing subscription
        existing.update!(
          auth_token: mock_response[:access_token],
          refresh_token: mock_response[:refresh_token],
          expires_at: Time.current + mock_response[:expires_in].seconds,
          scope: mock_response[:scope],
          active: true
        )
        
        # Refresh data
        FetchTikTokDataJob.perform_later(existing.id)
        
        redirect_to dashboard_path, notice: "TikTok account reconnected successfully."
      else
        # Create a new subscription
        subscription = current_user.subscriptions.create!(
          tiktok_uid: mock_response[:open_id],
          channel_id: mock_response[:open_id],
          account_name: "TikTok Account #{current_user.id}",
          account_username: "@tiktok_user_#{current_user.id}",
          auth_token: mock_response[:access_token],
          refresh_token: mock_response[:refresh_token],
          expires_at: Time.current + mock_response[:expires_in].seconds,
          scope: mock_response[:scope],
          platform: 'tiktok',
          active: true,
          enable_realtime: true
        )
        
        # Track platform connection server-side (critical event)
        PosthogService.track_platform_connection(
          user: current_user,
          platform: 'tiktok',
          connection_type: 'basic',
          success: true
        )
        
        # Create initial analytics snapshot to avoid validation errors
        create_initial_snapshot(subscription)
        
        # Start fetching data
        FetchTikTokDataJob.perform_later(subscription.id)
        
        redirect_to dashboard_path, notice: "TikTok account connected successfully."
      end
    rescue => e
      Rails.logger.error "TikTok callback error: #{e.message}"
      redirect_to subscriptions_path, alert: "Failed to connect TikTok account. Please try again."
    end
  end

  def destroy
    platform_name = @subscription.platform
    
    # Track platform disconnection server-side before destroying
    PosthogService.track_platform_disconnection(
      user: current_user,
      platform: platform_name
    )
    
    @subscription.destroy
    
    redirect_to subscriptions_path, notice: "#{platform_name.capitalize} account disconnected successfully."
  end
  
  private
  
  def set_subscription
    @subscription = current_user.subscriptions.find(params[:id])
  end
  
  def subscription_params
    params.require(:subscription).permit(:tiktok_uid, :auth_token, :platform)
  end
  
  def create_initial_snapshot(subscription)
    # Create an initial analytics snapshot to avoid validation errors
    # Only create if one doesn't exist for today
    today = Date.current
    
    unless subscription.analytics_snapshots.exists?(snapshot_date: today)
      subscription.analytics_snapshots.create!(
        snapshot_date: today,
        follower_count: 0,
        total_views: 0,
        total_likes: 0,
        revenue_cents: 0
      )
    end
    
    # Also create a daily stat record
    unless subscription.daily_stats.exists?(date: today)
      subscription.daily_stats.create!(
        date: today,
        views: 0,
        followers: 0,
        revenue: 0
      )
    end
  end
end

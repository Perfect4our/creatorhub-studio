require 'net/http'
require 'json'

class YoutubeService < BasePlatformService
  YOUTUBE_API_BASE_URL = 'https://www.googleapis.com/youtube/v3'
  YOUTUBE_ANALYTICS_API_BASE_URL = 'https://youtubeanalytics.googleapis.com/v2'
  OAUTH_BASE_URL = 'https://accounts.google.com/o/oauth2/v2'
  TOKEN_URL = 'https://oauth2.googleapis.com/token'
  
  def initialize(subscription = nil)
    super(subscription)
    @api_key = Rails.application.credentials.youtube&.api_key || ENV['YOUTUBE_API_KEY']
    @client_id = Rails.application.credentials.youtube&.client_id || ENV['YOUTUBE_CLIENT_ID']
    @client_secret = Rails.application.credentials.youtube&.client_secret || ENV['YOUTUBE_CLIENT_SECRET']
  end
  
  # Generate OAuth URL for YouTube with Analytics API scopes
  def oauth_url(redirect_uri, analytics_enabled = false)
    # Base scope for reading channel data
    scopes = ['https://www.googleapis.com/auth/youtube.readonly']
    
    # Add Analytics API scope if enabled (requires Google approval)
    if analytics_enabled
      scopes << 'https://www.googleapis.com/auth/yt-analytics.readonly'
      scopes << 'https://www.googleapis.com/auth/yt-analytics-monetary.readonly'
    end
    
    params = {
      client_id: @client_id,
      redirect_uri: redirect_uri,
      scope: scopes.join(' '),
      response_type: 'code',
      access_type: 'offline',
      prompt: 'consent'
    }
    
    query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    "#{OAUTH_BASE_URL}/auth?#{query_string}"
  end
  
  # Exchange authorization code for access token
  def exchange_code_for_token(code, redirect_uri)
    return mock_token_response unless @client_id && @client_secret
    
    uri = URI(TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request.set_form_data({
      code: code,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: redirect_uri,
      grant_type: 'authorization_code'
    })
    
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "YouTube token exchange failed: #{response.body}"
      raise "Failed to exchange code for token"
    end
  end
  
  # Get channel information
  def get_channel_info(access_token = nil)
    token = access_token || @subscription&.auth_token
    
    unless token && @api_key
      Rails.logger.warn("Missing YouTube API credentials - token: #{!!token}, api_key: #{!!@api_key}")
      return mock_channel_info
    end
    
    uri = URI("#{YOUTUBE_API_BASE_URL}/channels")
    params = {
      part: 'snippet,statistics',
      mine: 'true',
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{token}"
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['items'] && data['items'].any?
        channel = data['items'].first
        {
          channel_id: channel['id'],
          title: channel['snippet']['title'],
          description: channel['snippet']['description'],
          subscriber_count: channel['statistics']['subscriberCount'].to_i,
          view_count: channel['statistics']['viewCount'].to_i,
          video_count: channel['statistics']['videoCount'].to_i,
          thumbnail_url: channel['snippet']['thumbnails']['default']['url']
        }
      else
        raise "No channel found"
      end
    else
      Rails.logger.error "YouTube API error: #{response.body}"
      raise "Failed to fetch channel info"
    end
  end
  
  # Get channel videos
  def get_videos(max_results = 50)
    return mock_videos unless @subscription&.auth_token && @api_key
    
    begin
      # First get the channel info to get the uploads playlist ID
      channel_info = get_channel_info
      return [] unless channel_info && channel_info[:channel_id]
      
      # Convert channel ID to uploads playlist ID (UCxxx -> UUxxx)
      uploads_playlist_id = "UU#{channel_info[:channel_id][2..-1]}"
      
      uri = URI("#{YOUTUBE_API_BASE_URL}/playlistItems")
      params = {
        part: 'snippet,contentDetails',
        playlistId: uploads_playlist_id,
        maxResults: [max_results, 50].min, # Cap at 50 to avoid quota issues
        key: @api_key
      }
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@subscription.auth_token}"
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        videos = []
        
        data['items']&.each do |item|
          next unless item['contentDetails'] && item['contentDetails']['videoId']
          
          video_id = item['contentDetails']['videoId']
          snippet = item['snippet']
          
          # Get video statistics (with error handling)
          video_stats = get_video_statistics(video_id)
          
          # Get thumbnail URL safely
          thumbnail_url = snippet.dig('thumbnails', 'medium', 'url') || 
                         snippet.dig('thumbnails', 'default', 'url') || 
                         snippet.dig('thumbnails', 'high', 'url')
          
          videos << {
            video_id: video_id,
            title: snippet['title'] || 'Untitled Video',
            description: snippet['description'] || '',
            published_at: snippet['publishedAt'] ? Time.parse(snippet['publishedAt']) : Time.current,
            thumbnail_url: thumbnail_url,
            view_count: video_stats[:view_count] || 0,
            like_count: video_stats[:like_count] || 0,
            comment_count: video_stats[:comment_count] || 0
          }
        end
        
        videos
      elsif response.code == '404'
        Rails.logger.warn "YouTube uploads playlist not found for channel #{channel_info[:channel_id]}"
        []
      else
        Rails.logger.error "YouTube videos API error (#{response.code}): #{response.body}"
        []
      end
    rescue => e
      Rails.logger.error "Error fetching YouTube videos: #{e.message}"
      []
    end
  end
  
  # Get video statistics
  def get_video_statistics(video_id)
    return { view_count: 0, like_count: 0, comment_count: 0 } unless @api_key
    
    uri = URI("#{YOUTUBE_API_BASE_URL}/videos")
    params = {
      part: 'statistics',
      id: video_id,
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['items'] && data['items'].any?
        stats = data['items'].first['statistics']
        {
          view_count: stats['viewCount'].to_i,
          like_count: stats['likeCount'].to_i,
          comment_count: stats['commentCount'].to_i
        }
      else
        { view_count: 0, like_count: 0, comment_count: 0 }
      end
    else
      Rails.logger.error "YouTube video stats API error: #{response.body}"
      { view_count: 0, like_count: 0, comment_count: 0 }
    end
  end
  
  # Refresh access token
  def refresh_token
    return mock_token_response unless @subscription&.refresh_token && @client_id && @client_secret
    
    uri = URI(TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request.set_form_data({
      refresh_token: @subscription.refresh_token,
      client_id: @client_id,
      client_secret: @client_secret,
      grant_type: 'refresh_token'
    })
    
    response = http.request(request)
    
    if response.code == '200'
      token_data = JSON.parse(response.body)
      
      # Update subscription with new token
      @subscription.update!(
        auth_token: token_data['access_token'],
        expires_at: Time.current + token_data['expires_in'].seconds
      )
      
      token_data
    else
      Rails.logger.error "YouTube token refresh failed: #{response.body}"
      raise "Failed to refresh token"
    end
  end
  
  # Get analytics data from YouTube Analytics API
  def get_analytics_data(start_date = 30.days.ago, end_date = Date.current)
    return mock_analytics_data(start_date, end_date) unless analytics_api_available?
    
    begin
      # Get channel ID first
      channel_info = get_channel_info
      channel_id = channel_info[:channel_id]
      
      # Format dates for YouTube Analytics API
      start_date_str = start_date.strftime('%Y-%m-%d')
      end_date_str = end_date.strftime('%Y-%m-%d')
      
      # Get basic analytics data
      analytics_data = {
        views_data: get_views_analytics(channel_id, start_date_str, end_date_str),
        subscriber_data: get_subscriber_analytics(channel_id, start_date_str, end_date_str),
        revenue_data: get_revenue_analytics(channel_id, start_date_str, end_date_str),
        demographics: get_demographics_data(channel_id, start_date_str, end_date_str),
        top_videos: get_top_videos_analytics(channel_id, start_date_str, end_date_str)
      }
      
      analytics_data
    rescue => e
      Rails.logger.error "YouTube Analytics API error: #{e.message}"
      # Fallback to mock data if Analytics API fails
      mock_analytics_data(start_date, end_date)
    end
  end
  
  # Get real-time analytics (last 48 hours)
  def get_realtime_analytics
    return mock_realtime_data unless analytics_api_available?
    
    begin
      channel_info = get_channel_info
      channel_id = channel_info[:channel_id]
      
      # YouTube Analytics API doesn't provide true real-time data
      # But we can get recent data (last few days)
      end_date = Date.current
      start_date = 2.days.ago.to_date
      
      {
        hourly_views: get_hourly_views(channel_id, start_date, end_date),
        current_subscribers: channel_info[:subscriber_count],
        recent_videos_performance: get_recent_videos_performance(channel_id)
      }
    rescue => e
      Rails.logger.error "YouTube real-time analytics error: #{e.message}"
      mock_realtime_data
    end
  end
  
  def sync!
    return false unless subscription&.platform == 'youtube'
    
    begin
      # Refresh token if expired and we have a refresh token
      if subscription.refresh_token && subscription.token_expired?
        Rails.logger.info("Refreshing expired YouTube token for subscription #{subscription.id}")
        refresh_token
        subscription.reload # Reload to get updated token
      end
      
      # Check if we have valid credentials
      unless subscription.auth_token && @api_key
        Rails.logger.warn("Missing YouTube credentials for subscription #{subscription.id}")
        return false
      end
      
      # Fetch real channel data from YouTube API
      Rails.logger.info("Fetching YouTube channel data for subscription #{subscription.id}")
      channel_data = get_channel_info
      
      unless channel_data && channel_data[:view_count] && channel_data[:subscriber_count]
        Rails.logger.error("Failed to get valid channel data for subscription #{subscription.id}")
        return false
      end
      
      # Calculate stats from real channel data
      total_views = channel_data[:view_count].to_i
      follower_count = channel_data[:subscriber_count].to_i
    revenue = calculate_estimated_revenue(total_views)
    
      # Get today's date
      today = Date.current
      
      # Update or create daily stat with real data
      daily_stat = subscription.daily_stats.find_or_initialize_by(date: today)
      daily_stat.assign_attributes(
      views: total_views,
      followers: follower_count,
        revenue: revenue,
        platform: 'youtube'
      )
      
      if daily_stat.save
        Rails.logger.info("Successfully synced YouTube data for subscription #{subscription.id}: #{total_views} views, #{follower_count} subscribers, $#{revenue} revenue")
        
        # Also update or create analytics snapshot
        snapshot = subscription.analytics_snapshots.find_or_initialize_by(snapshot_date: today)
        snapshot.assign_attributes(
          follower_count: follower_count,
          total_views: total_views,
          total_likes: 0, # YouTube API doesn't provide total likes easily
          revenue_cents: (revenue * 100).to_i
        )
        snapshot.save
        
        true
      else
        Rails.logger.error("Failed to save daily stat for subscription #{subscription.id}: #{daily_stat.errors.full_messages}")
        false
      end
      
  rescue => e
      Rails.logger.error("Error syncing YouTube stats for subscription #{subscription.id}: #{e.message}")
      Rails.logger.error("Error details: #{e.backtrace.first(5).join('\n')}")
    false
    end
  end
  
  # Get public stats for daily tracking (uses public YouTube Data API)
  def get_public_stats
    return mock_public_stats unless @subscription&.channel_id || @subscription&.tiktok_uid
    
    channel_id = @subscription.channel_id || @subscription.tiktok_uid
    
    begin
      # Get channel statistics using public API (no OAuth required)
      uri = URI("#{YOUTUBE_API_BASE_URL}/channels")
      params = {
        part: 'statistics',
        id: channel_id,
        key: @api_key
      }
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        if data['items'] && data['items'].any?
          stats = data['items'].first['statistics']
          
          # Get top videos using public API
          top_videos = get_public_videos(5)
          
          {
            total_views: stats['viewCount'].to_i,
            total_subscribers: stats['subscriberCount'].to_i,
            video_count: stats['videoCount'].to_i,
            top_videos: top_videos,
            metadata: {
              last_updated: Time.current,
              api_source: 'youtube_data_api_v3'
            }
          }
        else
          mock_public_stats
        end
      else
        Rails.logger.error "YouTube public stats API error: #{response.body}"
        mock_public_stats
      end
    rescue => e
      Rails.logger.error "Error fetching YouTube public stats: #{e.message}"
      mock_public_stats
    end
  end
  
  # Get public videos (no OAuth required, uses channel uploads)
  def get_public_videos(max_results = 5)
    return [] unless @api_key && (@subscription&.channel_id || @subscription&.tiktok_uid)
    
    channel_id = @subscription.channel_id || @subscription.tiktok_uid
    
    begin
      # Convert channel ID to uploads playlist ID (UC -> UU)
      uploads_playlist_id = channel_id.start_with?('UC') ? "UU#{channel_id[2..-1]}" : channel_id
      
      uri = URI("#{YOUTUBE_API_BASE_URL}/playlistItems")
      params = {
        part: 'snippet',
        playlistId: uploads_playlist_id,
        maxResults: max_results,
        key: @api_key
      }
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        videos = []
        
        data['items']&.each do |item|
          video_id = item.dig('snippet', 'resourceId', 'videoId')
          next unless video_id
          
          # Get video stats
          video_stats = get_video_statistics(video_id)
          
          videos << {
            video_id: video_id,
            title: item.dig('snippet', 'title') || 'Untitled',
            views: video_stats[:view_count] || 0,
            likes: video_stats[:like_count] || 0,
            comments: video_stats[:comment_count] || 0,
            published_at: item.dig('snippet', 'publishedAt')
          }
        end
        
        videos
      else
        []
      end
    rescue => e
      Rails.logger.error "Error fetching public YouTube videos: #{e.message}"
      []
    end
  end

  # Check if Analytics API is available (requires approved scopes)
  def analytics_api_available?
    return false unless @subscription&.auth_token
    
    # Check if the subscription has Analytics API scopes
    scope = @subscription.scope || ''
    scope.include?('yt-analytics.readonly')
  end
  
  # Get views analytics from YouTube Analytics API
  def get_views_analytics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'views',
      dimensions: 'day'
    }
    uri.query = URI.encode_www_form(params)
    
    response = make_analytics_request(uri)
    parse_time_series_data(response, 'views')
  end
  
  # Get subscriber analytics
  def get_subscriber_analytics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'subscribersGained,subscribersLost',
      dimensions: 'day'
    }
    uri.query = URI.encode_www_form(params)
    
    response = make_analytics_request(uri)
    parse_subscriber_data(response)
  end
  
  # Get revenue analytics (requires monetary scope)
  def get_revenue_analytics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'estimatedRevenue,estimatedAdRevenue,estimatedRedPartnerRevenue',
      dimensions: 'day'
    }
    uri.query = URI.encode_www_form(params)
    
    response = make_analytics_request(uri)
    parse_revenue_data(response)
  end
  
  # Get demographics data
  def get_demographics_data(channel_id, start_date, end_date)
    age_response = get_age_demographics(channel_id, start_date, end_date)
    gender_response = get_gender_demographics(channel_id, start_date, end_date)
    geography_response = get_geography_demographics(channel_id, start_date, end_date)
    
    {
      age_groups: parse_demographics_data(age_response),
      gender: parse_demographics_data(gender_response),
      geography: parse_demographics_data(geography_response)
    }
  end
  
  # Get top videos analytics
  def get_top_videos_analytics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'views,likes,comments,shares',
      dimensions: 'video',
      sort: '-views',
      maxResults: 10
    }
    uri.query = URI.encode_www_form(params)
    
    response = make_analytics_request(uri)
    parse_top_videos_data(response)
  end
  
  # Get hourly views (approximated from daily data)
  def get_hourly_views(channel_id, start_date, end_date)
    views_data = get_views_analytics(channel_id, start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d'))
    
    # Convert daily views to hourly estimates
    hourly_data = []
    views_data.each do |day_data|
      daily_views = day_data[:views]
      # Distribute views across 24 hours with realistic patterns
      24.times do |hour|
        # Peak hours: 18-22 (evening), low hours: 2-6 (early morning)
        multiplier = case hour
                    when 18..22 then 1.5
                    when 12..17 then 1.2
                    when 8..11 then 1.0
                    when 23, 0, 1 then 0.8
                    when 2..6 then 0.4
                    else 0.7
                    end
        
        hourly_views = (daily_views * multiplier / 24).round
        hourly_data << {
          hour: hour,
          date: day_data[:date],
          views: hourly_views
        }
      end
    end
    
    hourly_data.last(48) # Return last 48 hours
  end
  
  # Get recent videos performance
  def get_recent_videos_performance(channel_id)
    recent_videos = get_videos(10) # Get last 10 videos
    
    recent_videos.map do |video|
      {
        video_id: video[:video_id],
        title: video[:title],
        views: video[:view_count],
        likes: video[:like_count],
        comments: video[:comment_count],
        published_at: video[:published_at],
        thumbnail_url: video[:thumbnail_url]
      }
    end
  end
  
  private
  
  # Make authenticated request to YouTube Analytics API
  def make_analytics_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@subscription.auth_token}"
    
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "YouTube Analytics API error: #{response.body}"
      raise "Analytics API request failed: #{response.code}"
    end
  end
  
  # Parse time series data (views, watch time, etc.)
  def parse_time_series_data(response, metric_name)
    return [] unless response['rows']
    
    response['rows'].map do |row|
      {
        date: Date.parse(row[0]),
        metric_name.to_sym => row[1].to_i
      }
    end
  end
  
  # Parse subscriber data
  def parse_subscriber_data(response)
    return [] unless response['rows']
    
    response['rows'].map do |row|
      {
        date: Date.parse(row[0]),
        subscribers_gained: row[1].to_i,
        subscribers_lost: row[2].to_i,
        net_subscribers: row[1].to_i - row[2].to_i
      }
    end
  end
  
  # Parse revenue data
  def parse_revenue_data(response)
    return [] unless response['rows']
    
    response['rows'].map do |row|
      {
        date: Date.parse(row[0]),
        estimated_revenue: row[1].to_f,
        ad_revenue: row[2].to_f,
        red_revenue: row[3].to_f
      }
    end
  end
  
  # Parse demographics data
  def parse_demographics_data(response)
    return [] unless response['rows']
    
    response['rows'].map do |row|
      {
        dimension: row[0],
        views: row[1].to_i,
        percentage: row[2].to_f
      }
    end
  end
  
  # Parse top videos data
  def parse_top_videos_data(response)
    return [] unless response['rows']
    
    response['rows'].map do |row|
      {
        video_id: row[0],
        views: row[1].to_i,
        likes: row[2].to_i,
        comments: row[3].to_i,
        shares: row[4].to_i
      }
    end
  end
  
  # Get age demographics
  def get_age_demographics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'viewerPercentage',
      dimensions: 'ageGroup',
      sort: 'ageGroup'
    }
    uri.query = URI.encode_www_form(params)
    
    make_analytics_request(uri)
  end
  
  # Get gender demographics
  def get_gender_demographics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'viewerPercentage',
      dimensions: 'gender',
      sort: 'gender'
    }
    uri.query = URI.encode_www_form(params)
    
    make_analytics_request(uri)
  end
  
  # Get geography demographics
  def get_geography_demographics(channel_id, start_date, end_date)
    uri = URI("#{YOUTUBE_ANALYTICS_API_BASE_URL}/reports")
    params = {
      ids: "channel==#{channel_id}",
      startDate: start_date,
      endDate: end_date,
      metrics: 'views',
      dimensions: 'country',
      sort: '-views',
      maxResults: 10
    }
    uri.query = URI.encode_www_form(params)
    
    make_analytics_request(uri)
  end
  
  # Mock real-time data for fallback
  def mock_realtime_data
    {
      hourly_views: Array.new(48) { |i| { hour: i % 24, views: rand(50..500) } },
      current_subscribers: rand(1000..100000),
      recent_videos_performance: mock_videos.first(5)
    }
  end
  
  protected
  
  def fetch_profile_data
    # In a real app, this would call the YouTube API
    {
      display_name: "YouTube Channel #{subscription.id}",
      avatar_url: "https://placehold.co/200x200?text=YouTube",
      follower_count: rand(1000..1000000),
      following_count: rand(10..100),
      video_count: rand(10..500),
      total_likes: rand(10000..5000000)
    }
  end
  
  def fetch_videos
    # In a real app, this would call the YouTube API
    10.times.map do |i|
      {
        video_id: "yt_video_#{i}_#{Time.now.to_i}",
        title: "YouTube Video ##{i}",
        view_count: rand(500..500000),
        like_count: rand(50..50000),
        comment_count: rand(10..5000),
        share_count: rand(5..500),
        created_at_tiktok: rand(1..365).days.ago,
        thumbnail_url: "https://placehold.co/320x180?text=YouTube+#{i}"
      }
    end
  end
  
  private
  
  def calculate_estimated_revenue(views)
    # YouTube typically has higher CPM than TikTok
    (views * rand(0.002..0.007)).round(2)
  end
  
  # Mock responses for development/testing
  def mock_token_response
    {
      'access_token' => "mock_youtube_token_#{Time.now.to_i}",
      'refresh_token' => "mock_youtube_refresh_#{Time.now.to_i}",
      'expires_in' => 3600,
      'scope' => 'https://www.googleapis.com/auth/youtube.readonly',
      'token_type' => 'Bearer'
    }
  end
  
  def mock_channel_info
    {
      channel_id: "UC#{SecureRandom.hex(11)}",
      title: "Test YouTube Channel",
      description: "This is a test YouTube channel for development",
      subscriber_count: rand(1000..100000),
      view_count: rand(10000..1000000),
      video_count: rand(10..500),
      thumbnail_url: "https://via.placeholder.com/88x88"
    }
  end
  
  def mock_videos
    (1..10).map do |i|
      {
        video_id: SecureRandom.hex(5),
        title: "Test Video #{i}",
        description: "This is a test video description",
        published_at: rand(30.days).seconds.ago,
        thumbnail_url: "https://via.placeholder.com/120x90",
        view_count: rand(100..10000),
        like_count: rand(10..1000),
        comment_count: rand(1..100)
      }
    end
  end
  
  def mock_analytics_data(start_date, end_date)
    days = (end_date - start_date).to_i
    dates = (0..days).map { |i| start_date + i.days }
    
    {
      dates: dates,
      views: dates.map { rand(100..1000) },
      subscribers: dates.map { rand(1..50) },
      revenue: dates.map { rand(0..100) / 100.0 }
    }
  end
  
  def mock_public_stats
    {
      total_views: rand(10000..1000000),
      total_subscribers: rand(1000..100000),
      video_count: rand(10..500),
      top_videos: [
        { video_id: 'mock1', title: 'Top Video 1', views: rand(1000..50000), likes: rand(100..5000), comments: rand(10..500) },
        { video_id: 'mock2', title: 'Top Video 2', views: rand(1000..50000), likes: rand(100..5000), comments: rand(10..500) },
        { video_id: 'mock3', title: 'Top Video 3', views: rand(1000..50000), likes: rand(100..5000), comments: rand(10..500) }
      ],
      metadata: {
        last_updated: Time.current,
        api_source: 'mock_data'
      }
    }
  end
end

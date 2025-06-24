class TiktokService < BasePlatformService
  def initialize(subscription = nil)
    super(subscription)
    @client_id = get_credential('tiktok', 'client_id') || ENV['TIKTOK_CLIENT_ID']
    @client_secret = get_credential('tiktok', 'client_secret') || ENV['TIKTOK_CLIENT_SECRET']
  end
  
  # Safe credential access that never crashes
  def get_credential(service, key)
    Rails.application.credentials.dig(service.to_sym, key.to_sym)
  rescue => e
    Rails.logger.debug "Credentials access failed for #{service}.#{key}: #{e.class}"
    nil
  end
  
  def sync!
    return unless subscription.platform == 'tiktok'
    
    # Refresh token if expired
    subscription.refresh_access_token! if subscription.token_expired?
    
    # Fetch profile data
    profile_data = fetch_profile_data
    
    # Fetch videos
    videos = fetch_videos
    
    # Calculate stats
    total_views = videos.sum { |v| v[:view_count] }
    follower_count = profile_data[:follower_count]
    revenue = calculate_estimated_revenue(total_views)
    
    # Create daily stat
    create_daily_stat(
      views: total_views,
      followers: follower_count,
      revenue: revenue
    )
    
    # Update or create videos
    sync_videos(videos)
    
    true
  rescue => e
    Rails.logger.error("Error syncing TikTok stats for subscription ##{subscription.id}: #{e.message}")
    false
  end
  
  # Get public stats for daily tracking (mock implementation)
  def get_public_stats
    # TikTok doesn't have a public API like YouTube, so we'll use mock data
    # In a real implementation, this might scrape public profile data or use unofficial APIs
    {
      total_views: rand(50000..2000000),
      total_subscribers: rand(5000..500000),
      video_count: rand(20..1000),
      top_videos: [
        { video_id: 'tt_mock1', title: 'Viral TikTok 1', views: rand(10000..500000), likes: rand(1000..50000), comments: rand(100..5000) },
        { video_id: 'tt_mock2', title: 'Viral TikTok 2', views: rand(10000..500000), likes: rand(1000..50000), comments: rand(100..5000) },
        { video_id: 'tt_mock3', title: 'Viral TikTok 3', views: rand(10000..500000), likes: rand(1000..50000), comments: rand(100..5000) }
      ],
      metadata: {
        last_updated: Time.current,
        api_source: 'tiktok_mock_data'
      }
    }
  end
  
  protected
  
  def fetch_profile_data
    # In a real app, this would call the TikTok API
    # For now, we'll use the mock implementation from the subscription model
    subscription.fetch_profile_data
  end
  
  def fetch_videos
    # In a real app, this would call the TikTok API
    # For now, we'll use the mock implementation from the subscription model
    subscription.fetch_videos
  end
  
  def sync_videos(videos)
    videos.each do |video_data|
      video = subscription.tik_tok_videos.find_or_initialize_by(video_id: video_data[:video_id])
      
      video.update!(
        title: video_data[:title],
        view_count: video_data[:view_count],
        like_count: video_data[:like_count],
        comment_count: video_data[:comment_count],
        share_count: video_data[:share_count],
        created_at_tiktok: video_data[:created_at_tiktok],
        thumbnail_url: video_data[:thumbnail_url]
      )
    end
  end
  
  private
  
  def calculate_estimated_revenue(views)
    # Mock implementation - this is a simplified calculation
    # In reality, revenue depends on many factors
    (views * rand(0.001..0.005)).round(2)
  end
end

class Subscription < ApplicationRecord
  belongs_to :user
  has_many :tik_tok_videos, dependent: :destroy
  has_many :analytics_snapshots, dependent: :destroy
  has_many :daily_stats, dependent: :destroy
  has_many :daily_view_trackings, dependent: :destroy
  
  validates :tiktok_uid, presence: true, if: -> { platform == 'tiktok' }
  validates :auth_token, presence: true
  validates :platform, presence: true
  validates :channel_id, presence: true, uniqueness: { scope: [:user_id, :platform] }
  
  scope :active, -> { where(active: true) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  
  before_validation :set_default_platform
  before_validation :set_channel_id_if_missing
  
  def display_name
    account_name.presence || account_username.presence || "#{platform.capitalize} Account"
  end
  
  def token_expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def refresh_access_token!
    # Mock implementation - in production this would call the API
    # to refresh the token using the refresh_token
    update(
      auth_token: "new_mock_token_#{Time.now.to_i}",
      refresh_token: "new_mock_refresh_token_#{Time.now.to_i}",
      expires_at: 30.days.from_now
    )
  end
  
  def fetch_profile_data
    # Mock implementation - in production this would call the platform API
    {
      display_name: display_name,
      avatar_url: "https://placehold.co/200x200?text=#{platform}",
      follower_count: rand(1000..100000),
      following_count: rand(100..1000),
      video_count: rand(10..200),
      total_likes: rand(10000..1000000)
    }
  end
  
  def fetch_videos
    # Mock implementation - in production this would call the platform API
    10.times.map do |i|
      {
        video_id: "video_#{i}_#{Time.now.to_i}",
        title: "#{platform.capitalize} Video ##{i}",
        view_count: rand(1000..100000),
        like_count: rand(100..10000),
        comment_count: rand(10..1000),
        share_count: rand(5..500),
        created_at_tiktok: rand(1..365).days.ago,
        thumbnail_url: "https://placehold.co/320x180?text=#{platform}+#{i}"
      }
    end
  end
  
  def create_daily_snapshot
    profile_data = fetch_profile_data
    videos = tik_tok_videos
    
    analytics_snapshots.create!(
      follower_count: profile_data[:follower_count],
      total_views: videos.sum(:view_count),
      total_likes: videos.sum(:like_count),
      revenue_cents: calculate_estimated_revenue(videos.sum(:view_count)),
      snapshot_date: Date.current
    )
  end
  
  def service_class
    case platform&.downcase
    when 'tiktok'
      TiktokService
    when 'youtube'
      YoutubeService
    when 'instagram'
      InstagramService
    when 'twitter'
      TwitterService
    when 'twitch'
      TwitchService
    when 'linkedin'
      LinkedinService
    when 'facebook'
      FacebookService
    else
      nil
    end
  end
  
  def sync_stats!
    service = service_class&.new(self)
    service&.sync!
  end
  
  # Track daily views using public data
  def track_daily_views!
    service = service_class&.new(self)
    return unless service
    
    today = Date.current
    existing_tracking = daily_view_trackings.find_by(tracked_date: today)
    
    # Get current public stats
    current_stats = service.get_public_stats
    
    if existing_tracking
      # Update existing record with current stats
      previous_views = existing_tracking.total_views
      previous_subscribers = existing_tracking.total_subscribers
      
      existing_tracking.update!(
        total_views: current_stats[:total_views] || 0,
        total_subscribers: current_stats[:total_subscribers] || 0,
        daily_view_gain: (current_stats[:total_views] || 0) - previous_views,
        daily_subscriber_gain: (current_stats[:total_subscribers] || 0) - previous_subscribers,
        estimated_revenue: calculate_estimated_revenue_decimal(current_stats[:total_views] || 0),
        video_performance: current_stats[:top_videos] || [],
        platform_metadata: current_stats[:metadata] || {}
      )
    else
      # Create new tracking record
      # Try to get yesterday's data to calculate gains
      yesterday_tracking = daily_view_trackings.find_by(tracked_date: today - 1.day)
      previous_views = yesterday_tracking&.total_views || 0
      previous_subscribers = yesterday_tracking&.total_subscribers || 0
      
      daily_view_trackings.create!(
        tracked_date: today,
        total_views: current_stats[:total_views] || 0,
        total_subscribers: current_stats[:total_subscribers] || 0,
        daily_view_gain: (current_stats[:total_views] || 0) - previous_views,
        daily_subscriber_gain: (current_stats[:total_subscribers] || 0) - previous_subscribers,
        estimated_revenue: calculate_estimated_revenue_decimal(current_stats[:total_views] || 0),
        video_performance: current_stats[:top_videos] || [],
        platform_metadata: current_stats[:metadata] || {}
      )
    end
  end
  
  private
  
  def calculate_estimated_revenue(views)
    # Mock implementation - this is a simplified calculation
    # In reality, revenue depends on many factors
    (views * rand(0.001..0.005) * 100).to_i # Convert to cents
  end
  
  def calculate_estimated_revenue_decimal(views)
    # Calculate revenue as decimal for the new tracking system
    views * rand(0.001..0.005)
  end
  
  def set_default_platform
    self.platform ||= 'unknown'
  end
  
  def set_channel_id_if_missing
    if channel_id.blank?
      # Generate a channel_id based on platform-specific identifier
      case platform&.downcase
      when 'youtube'
        self.channel_id = tiktok_uid.presence || "yt_#{SecureRandom.hex(8)}"
      when 'tiktok'
        self.channel_id = tiktok_uid.presence || "tt_#{SecureRandom.hex(8)}"
      else
        self.channel_id = tiktok_uid.presence || "#{platform}_#{SecureRandom.hex(8)}"
      end
    end
  end
end

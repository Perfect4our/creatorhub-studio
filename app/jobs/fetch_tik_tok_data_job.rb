class FetchTikTokDataJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription
    
    # Refresh token if expired
    if subscription.token_expired?
      subscription.refresh_access_token!
    end
    
    # Fetch and store videos
    fetch_and_store_videos(subscription)
    
    # Create daily analytics snapshot
    subscription.create_daily_snapshot
    
    # Schedule next run for tomorrow
    FetchTikTokDataJob.set(wait: 1.day).perform_later(subscription_id)
  end
  
  private
  
  def fetch_and_store_videos(subscription)
    # Fetch videos from TikTok API (mock)
    videos_data = subscription.fetch_videos
    
    videos_data.each do |video_data|
      # Find or create video
      video = subscription.tik_tok_videos.find_or_initialize_by(video_id: video_data[:video_id])
      
      # Update attributes
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
end

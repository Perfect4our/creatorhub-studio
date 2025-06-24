class VideosController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @subscriptions = current_user.subscriptions.active
    @selected_platform = params[:platform] || 'all'
    @available_platforms = @subscriptions.pluck(:platform).uniq
    @sort_by = params[:sort_by] || 'newest'
    @search_query = params[:search]
    
    # Get videos from all platforms
    @all_videos = []
    
    @subscriptions.each do |subscription|
      platform = subscription.platform
      
      case platform
      when 'tiktok'
        # Get TikTok videos from database
        tiktok_videos = TikTokVideo.where(subscription_id: subscription.id)
        @all_videos += tiktok_videos.map do |video|
          {
            id: video.id,
            video_id: video.video_id,
            title: video.title,
            description: video.description,
            view_count: video.view_count,
            like_count: video.like_count,
            comment_count: video.comment_count,
            created_at_tiktok: video.created_at_tiktok,
            thumbnail_url: video.thumbnail_url,
            platform: 'tiktok',
            engagement_rate: calculate_engagement_rate(video.view_count, video.like_count, video.comment_count),
            source: 'database'
          }
        end
      when 'youtube'
        # Get YouTube videos from API
        begin
          youtube_service = YoutubeService.new(subscription)
          youtube_videos = youtube_service.get_videos(50)
          @all_videos += youtube_videos.map do |video|
            {
              video_id: video[:video_id],
              title: video[:title],
              description: video[:description],
              view_count: video[:view_count],
              like_count: video[:like_count],
              comment_count: video[:comment_count],
              created_at_tiktok: video[:published_at],
              thumbnail_url: video[:thumbnail_url],
              platform: 'youtube',
              engagement_rate: calculate_engagement_rate(video[:view_count], video[:like_count], video[:comment_count]),
              source: 'api'
            }
          end
        rescue => e
          Rails.logger.error "Error fetching YouTube videos: #{e.message}"
        end
      end
    end
    
    # Filter by platform if specified
    if @selected_platform != 'all'
      @all_videos = @all_videos.select { |v| v[:platform] == @selected_platform }
    end
    
    # Filter by search query if provided
    if @search_query.present?
      @all_videos = @all_videos.select do |video|
        video[:title]&.downcase&.include?(@search_query.downcase) ||
        video[:description]&.downcase&.include?(@search_query.downcase)
      end
    end
    
    # Sort videos
    @all_videos = sort_videos(@all_videos, @sort_by)
    
    # Implement pagination
    @page = (params[:page] || 1).to_i
    @per_page = 12
    @total_count = @all_videos.length
    @total_pages = (@total_count.to_f / @per_page).ceil
    
    start_index = (@page - 1) * @per_page
    end_index = start_index + @per_page - 1
    @videos = @all_videos[start_index..end_index] || []
  end
  
  def show
    @video = TikTokVideo.find(params[:id])
    
    # Ensure the video belongs to the current user
    unless @video.subscription.user == current_user
      redirect_to videos_path, alert: "You don't have access to this video."
      return
    end
    
    # Get daily stats for this video's platform
    @platform_stats = @video.subscription.daily_stats.recent.first(7)
  end
  
  private
  
  def calculate_engagement_rate(views, likes, comments)
    return 0 if views.nil? || views == 0
    
    total_engagement = (likes || 0) + (comments || 0)
    ((total_engagement.to_f / views) * 100).round(1)
  end
  
  def sort_videos(videos, sort_by)
    case sort_by
    when 'newest'
      videos.sort_by { |v| v[:created_at_tiktok] || Time.current }.reverse
    when 'oldest'
      videos.sort_by { |v| v[:created_at_tiktok] || Time.current }
    when 'most_viewed'
      videos.sort_by { |v| -(v[:view_count] || 0) }
    when 'least_viewed'
      videos.sort_by { |v| v[:view_count] || 0 }
    when 'engagement'
      videos.sort_by { |v| -(v[:engagement_rate] || 0) }
    else
      videos.sort_by { |v| v[:created_at_tiktok] || Time.current }.reverse
    end
  end
end

module Api
  module V1
    class VideosController < ApplicationController
      before_action :authenticate_user!
      
      def index
        subscription_id = params[:subscription_id]
        
        if subscription_id
          videos = TikTokVideo.where(subscription_id: subscription_id)
                             .order(created_at_tiktok: :desc)
                             .limit(params[:limit] || 10)
        else
          videos = current_user.subscriptions.flat_map do |subscription|
            subscription.tik_tok_videos.order(created_at_tiktok: :desc).limit(5)
          end
        end
        
        render json: {
          success: true,
          videos: videos.as_json(
            except: [:created_at, :updated_at],
            methods: [:engagement_rate, :thumbnail_url]
          )
        }
      end
      
      def show
        video = TikTokVideo.find_by(id: params[:id])
        
        if video && video.subscription.user_id == current_user.id
          render json: {
            success: true,
            video: video.as_json(
              except: [:created_at, :updated_at],
              methods: [:engagement_rate, :thumbnail_url]
            )
          }
        else
          render json: { error: 'Video not found' }, status: :not_found
        end
      end
    end
  end
end

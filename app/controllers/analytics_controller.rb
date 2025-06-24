class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  
  def demographics
    @subscriptions = current_user.subscriptions.active
    @selected_platform = params[:platform] || 'all'
    
    # Get available platforms for the user
    @available_platforms = @subscriptions.pluck(:platform).uniq
    
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
end

require 'ostruct'

module Api
  module V1
    class AnalyticsController < ApplicationController
      before_action :authenticate_user!
      
      def index
        subscription_id = params[:subscription_id]
        period = params[:period] || 30
        
        # In a real app, we would fetch this data from the TikTok API
        # For now, we'll generate mock data
        
        render json: {
          success: true,
          current_stats: {
            total_views: rand(400000..500000),
            follower_count: rand(40000..50000),
            revenue: rand(5000..6000)
          },
          chart_data: generate_chart_data(period.to_i)
        }
      end
      
      private
      
      def generate_chart_data(days)
        dates = []
        views = []
        followers = []
        likes = []
        comments = []
        shares = []
        revenue = []
        
        (days.days.ago.to_date..Date.today).each do |date|
          dates << date.strftime('%b %d')
          views << rand(1000..50000)
          followers << rand(100..1000)
          likes << rand(500..10000)
          comments << rand(50..1000)
          shares << rand(20..500)
          revenue << rand(10..500)
        end
        
        {
          dates: dates,
          metrics: {
            views: views,
            followers: followers,
            likes: likes,
            comments: comments,
            shares: shares,
            revenue: revenue
          }
        }
      end
    end
  end
end

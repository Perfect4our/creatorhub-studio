class TikTokVideo < ApplicationRecord
  belongs_to :subscription
  
  validates :video_id, presence: true, uniqueness: { scope: :subscription_id }
  validates :title, presence: true
  validates :view_count, :like_count, :comment_count, :share_count, numericality: { greater_than_or_equal_to: 0 }
  
  def engagement_rate
    return 0 if view_count.nil? || view_count.zero?
    
    engagement = (like_count.to_i + comment_count.to_i + share_count.to_i).to_f
    rate = (engagement / view_count) * 100
    rate.round(2)
  end
  
  def thumbnail_url
    super || "https://via.placeholder.com/320x180?text=TikTok+Video"
  end
end

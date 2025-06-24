class AnalyticsSnapshot < ApplicationRecord
  belongs_to :subscription
  
  validates :follower_count, :total_views, :total_likes, :revenue_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :snapshot_date, presence: true
  validates :snapshot_date, uniqueness: { scope: :subscription_id }
  
  def revenue
    revenue_cents / 100.0
  end
end

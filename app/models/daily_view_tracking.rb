class DailyViewTracking < ApplicationRecord
  belongs_to :subscription
  
  validates :tracked_date, presence: true, uniqueness: { scope: :subscription_id }
  validates :total_views, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_subscribers, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :recent, -> { order(tracked_date: :desc) }
  scope :for_date_range, ->(start_date, end_date) { where(tracked_date: start_date..end_date) }
  scope :with_gains, -> { where('daily_view_gain > 0 OR daily_subscriber_gain > 0') }
  
  def growth_percentage_views
    return 0 if total_views == 0 || daily_view_gain == 0
    ((daily_view_gain.to_f / (total_views - daily_view_gain)) * 100).round(2)
  end
  
  def growth_percentage_subscribers
    return 0 if total_subscribers == 0 || daily_subscriber_gain == 0
    ((daily_subscriber_gain.to_f / (total_subscribers - daily_subscriber_gain)) * 100).round(2)
  end
  
  def formatted_date
    tracked_date.strftime('%b %d, %Y')
  end
  
  def self.chart_data_for_subscription(subscription, days = 30)
    trackings = subscription.daily_view_trackings
                          .for_date_range(days.days.ago.to_date, Date.current)
                          .order(:tracked_date)
    
    {
      labels: trackings.map(&:formatted_date),
      views: trackings.map(&:total_views),
      subscribers: trackings.map(&:total_subscribers),
      daily_gains: trackings.map(&:daily_view_gain),
      subscriber_gains: trackings.map(&:daily_subscriber_gain)
    }
  end
end 
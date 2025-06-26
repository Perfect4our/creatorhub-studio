class DailyViewTracking < ApplicationRecord
  belongs_to :subscription
  
  validates :tracked_date, presence: true, uniqueness: { scope: :subscription_id }
  validates :total_views, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_subscribers, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :recent, -> { order(tracked_date: :desc) }
  scope :for_date_range, ->(start_date, end_date) { where(tracked_date: start_date..end_date) }
  scope :with_gains, -> { where('daily_view_gain > 0 OR daily_subscriber_gain > 0') }
  scope :latest_for_subscription, ->(subscription_id) { where(subscription_id: subscription_id).order(:tracked_date).last }
  
  # Performance-optimized scopes
  scope :with_subscription, -> { includes(:subscription) }
  scope :by_subscription, ->(subscription_id) { where(subscription_id: subscription_id) }
  scope :ordered_by_date, -> { order(:tracked_date) }
  scope :ordered_by_date_desc, -> { order(tracked_date: :desc) }
  
  # Dashboard-specific optimized queries
  def self.latest_stats_for_subscriptions(subscription_ids)
    # Single query to get latest tracking for multiple subscriptions
    subquery = select('DISTINCT ON (subscription_id) subscription_id, total_views, total_subscribers, estimated_revenue, tracked_date')
               .where(subscription_id: subscription_ids)
               .order(:subscription_id, tracked_date: :desc)
    
    connection.exec_query(subquery.to_sql).map do |row|
      {
        subscription_id: row['subscription_id'],
        total_views: row['total_views'],
        total_subscribers: row['total_subscribers'],
        estimated_revenue: row['estimated_revenue']&.to_f || 0
      }
    end
  end
  
  def self.efficient_chart_data(subscription_id, start_date, end_date)
    # Single efficient query using pluck for chart data
    data = where(subscription_id: subscription_id)
           .where(tracked_date: start_date..end_date)
           .order(:tracked_date)
           .pluck(:tracked_date, :daily_view_gain, :daily_subscriber_gain, :estimated_revenue, :total_views, :total_subscribers)
    
    {
      dates: data.map { |row| row[0].strftime('%Y-%m-%d') },
      daily_view_gains: data.map { |row| row[1] || 0 },
      daily_subscriber_gains: data.map { |row| row[2] || 0 },
      daily_revenue: data.map { |row| row[3]&.to_f || 0 },
      total_views: data.map { |row| row[4] || 0 },
      total_subscribers: data.map { |row| row[5] || 0 }
    }
  end
  
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
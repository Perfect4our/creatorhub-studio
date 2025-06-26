class DailyStat < ApplicationRecord
  belongs_to :subscription
  
  validates :date, presence: true
  validates :views, :followers, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :platform, presence: true
  
  scope :recent, -> { order(date: :desc) }
  scope :last_48_hours, -> { where('date >= ?', 2.days.ago.to_date) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_subscription, ->(subscription_id) { where(subscription_id: subscription_id) }
  scope :ordered_by_date, -> { order(:date) }
  scope :ordered_by_date_desc, -> { order(date: :desc) }
  scope :with_subscription, -> { includes(:subscription) }
  
  # Dashboard-specific optimized queries
  def self.latest_stats_for_subscriptions(subscription_ids)
    # Single query to get latest stats for multiple subscriptions
    subquery = select('DISTINCT ON (subscription_id) subscription_id, views, followers, revenue, date')
               .where(subscription_id: subscription_ids)
               .order(:subscription_id, date: :desc)
    
    connection.exec_query(subquery.to_sql).map do |row|
      {
        subscription_id: row['subscription_id'],
        views: row['views'] || 0,
        followers: row['followers'] || 0,
        revenue: row['revenue']&.to_f || 0
      }
    end
  end
  
  def self.efficient_chart_data(subscription_id, start_date, end_date)
    # Single efficient query using pluck for chart data
    data = where(subscription_id: subscription_id)
           .where(date: start_date..end_date)
           .order(:date)
           .pluck(:date, :views, :followers, :revenue)
    
    {
      dates: data.map { |row| row[0].strftime('%Y-%m-%d') },
      views: data.map { |row| row[1] || 0 },
      followers: data.map { |row| row[2] || 0 },
      revenue: data.map { |row| row[3]&.to_f || 0 }
    }
  end
  
  def self.combined_stats_for_user(user_id, start_date = nil, end_date = nil)
    # Efficient query to get combined stats across all user's subscriptions
    query = joins(:subscription)
            .where(subscriptions: { user_id: user_id, active: true })
    
    if start_date && end_date
      query = query.where(date: start_date..end_date)
    end
    
    # Get the latest stats for each subscription
    stats = query.group(:subscription_id)
                 .maximum(:date)
                 .map do |subscription_id, max_date|
                   where(subscription_id: subscription_id, date: max_date)
                     .pick(:views, :followers, :revenue)
                 end
    
    {
      total_views: stats.sum { |stat| stat[0] || 0 },
      total_followers: stats.sum { |stat| stat[1] || 0 },
      total_revenue: stats.sum { |stat| stat[2]&.to_f || 0 }
    }
  end
  
  def self.total_views
    sum(:views)
  end
  
  def self.total_followers
    maximum(:followers) || 0
  end
  
  def self.total_revenue
    sum(:revenue)
  end
end

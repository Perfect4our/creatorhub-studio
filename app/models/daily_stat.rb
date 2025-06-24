class DailyStat < ApplicationRecord
  belongs_to :subscription
  
  validates :date, presence: true
  validates :views, :followers, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :platform, presence: true
  
  scope :recent, -> { order(date: :desc) }
  scope :last_48_hours, -> { where('date >= ?', 2.days.ago.to_date) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  
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

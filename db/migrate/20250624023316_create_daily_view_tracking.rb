class CreateDailyViewTracking < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_view_trackings do |t|
      t.references :subscription, null: false, foreign_key: true
      t.date :tracked_date, null: false
      t.bigint :total_views, default: 0
      t.bigint :total_subscribers, default: 0
      t.bigint :daily_view_gain, default: 0
      t.bigint :daily_subscriber_gain, default: 0
      t.decimal :estimated_revenue, precision: 10, scale: 2, default: 0.0
      t.json :video_performance # Store top performing videos for the day
      t.json :platform_metadata # Store platform-specific data
      
      t.timestamps
    end
    
    # Ensure one record per subscription per day
    add_index :daily_view_trackings, [:subscription_id, :tracked_date], unique: true, name: 'index_daily_tracking_unique'
    
    # Index for fast date-range queries
    add_index :daily_view_trackings, :tracked_date
    add_index :daily_view_trackings, [:subscription_id, :tracked_date], name: 'index_daily_tracking_lookup'
  end
end

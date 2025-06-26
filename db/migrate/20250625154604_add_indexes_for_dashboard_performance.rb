class AddIndexesForDashboardPerformance < ActiveRecord::Migration[8.0]
  def change
    # Add composite indexes for common dashboard queries
    
    # Daily stats queries - often filtered by subscription and date range
    add_index :daily_stats, [:subscription_id, :date], name: 'index_daily_stats_on_subscription_and_date'
    
    # Daily view tracking queries - often filtered by subscription and tracked_date
    add_index :daily_view_trackings, [:subscription_id, :tracked_date], name: 'index_daily_view_trackings_on_subscription_and_date'
    
    # Subscription queries - often filtered by user and active status
    add_index :subscriptions, [:user_id, :active], name: 'index_subscriptions_on_user_and_active'
    
    # Subscription platform queries - useful for platform filtering
    add_index :subscriptions, [:user_id, :platform, :active], name: 'index_subscriptions_on_user_platform_active'
    
    # TikTok videos - often ordered by creation date for a subscription
    add_index :tik_tok_videos, [:subscription_id, :created_at_tiktok], name: 'index_tik_tok_videos_on_subscription_and_date'
    
    # Analytics snapshots - if used for historical data
    add_index :analytics_snapshots, [:subscription_id, :snapshot_date], name: 'index_analytics_snapshots_on_subscription_and_date'
    
    # Daily view trackings - for recent queries (common pattern)
    add_index :daily_view_trackings, [:subscription_id, :id], name: 'index_daily_view_trackings_on_subscription_and_id'
    
    # Daily stats - for recent queries (common pattern)  
    add_index :daily_stats, [:subscription_id, :id], name: 'index_daily_stats_on_subscription_and_id'
  end
  
  def down
    # Remove indexes in reverse order
    remove_index :daily_stats, name: 'index_daily_stats_on_subscription_and_id'
    remove_index :daily_view_trackings, name: 'index_daily_view_trackings_on_subscription_and_id'
    remove_index :analytics_snapshots, name: 'index_analytics_snapshots_on_subscription_and_date'
    remove_index :tik_tok_videos, name: 'index_tik_tok_videos_on_subscription_and_date'
    remove_index :subscriptions, name: 'index_subscriptions_on_user_platform_active'
    remove_index :subscriptions, name: 'index_subscriptions_on_user_and_active'
    remove_index :daily_view_trackings, name: 'index_daily_view_trackings_on_subscription_and_date'
    remove_index :daily_stats, name: 'index_daily_stats_on_subscription_and_date'
  end
end

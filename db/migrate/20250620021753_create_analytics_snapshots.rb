class CreateAnalyticsSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_snapshots do |t|
      t.references :subscription, null: false, foreign_key: true
      t.integer :follower_count
      t.integer :total_views
      t.integer :total_likes
      t.integer :revenue_cents
      t.date :snapshot_date

      t.timestamps
    end
  end
end

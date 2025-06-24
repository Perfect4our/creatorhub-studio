class CreateTikTokVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :tik_tok_videos do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :video_id
      t.string :title
      t.integer :view_count
      t.integer :like_count
      t.integer :comment_count
      t.integer :share_count
      t.datetime :created_at_tiktok
      t.string :thumbnail_url

      t.timestamps
    end
  end
end

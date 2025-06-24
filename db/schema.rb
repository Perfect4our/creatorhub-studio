# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_24_023316) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_snapshots", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.integer "follower_count"
    t.integer "total_views"
    t.integer "total_likes"
    t.integer "revenue_cents"
    t.date "snapshot_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_analytics_snapshots_on_subscription_id"
  end

  create_table "daily_stats", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.date "date"
    t.integer "views"
    t.integer "followers"
    t.decimal "revenue"
    t.string "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_daily_stats_on_subscription_id"
  end

  create_table "daily_view_trackings", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.date "tracked_date", null: false
    t.bigint "total_views", default: 0
    t.bigint "total_subscribers", default: 0
    t.bigint "daily_view_gain", default: 0
    t.bigint "daily_subscriber_gain", default: 0
    t.decimal "estimated_revenue", precision: 10, scale: 2, default: "0.0"
    t.json "video_performance"
    t.json "platform_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id", "tracked_date"], name: "index_daily_tracking_lookup"
    t.index ["subscription_id", "tracked_date"], name: "index_daily_tracking_unique", unique: true
    t.index ["subscription_id"], name: "index_daily_view_trackings_on_subscription_id"
    t.index ["tracked_date"], name: "index_daily_view_trackings_on_tracked_date"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "tiktok_uid"
    t.string "auth_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "refresh_token"
    t.datetime "expires_at"
    t.string "scope"
    t.string "platform"
    t.boolean "active", default: true
    t.boolean "enable_realtime", default: true
    t.string "account_name"
    t.string "account_username"
    t.string "channel_id"
    t.index ["user_id", "platform", "channel_id"], name: "index_subscriptions_on_user_platform_channel", unique: true
    t.index ["user_id", "platform"], name: "index_subscriptions_on_user_platform"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tik_tok_videos", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.string "video_id"
    t.string "title"
    t.integer "view_count"
    t.integer "like_count"
    t.integer "comment_count"
    t.integer "share_count"
    t.datetime "created_at_tiktok"
    t.string "thumbnail_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_tik_tok_videos_on_subscription_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "admin", default: false, null: false
    t.boolean "permanent_subscription", default: false, null: false
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "analytics_snapshots", "subscriptions"
  add_foreign_key "daily_stats", "subscriptions"
  add_foreign_key "daily_view_trackings", "subscriptions"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tik_tok_videos", "subscriptions"
end

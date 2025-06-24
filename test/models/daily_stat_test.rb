require 'test_helper'

class DailyStatTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @subscription = Subscription.create!(
      user: @user,
      tiktok_uid: "test_uid_#{Time.now.to_i}",
      auth_token: "test_token",
      platform: "tiktok"
    )
  end
  
  test "should create a valid daily stat" do
    daily_stat = DailyStat.new(
      subscription: @subscription,
      date: Date.current,
      views: 1000,
      followers: 500,
      revenue: 50.25,
      platform: "tiktok"
    )
    
    assert daily_stat.valid?
    assert daily_stat.save
  end
  
  test "should require date" do
    daily_stat = DailyStat.new(
      subscription: @subscription,
      views: 1000,
      followers: 500,
      revenue: 50.25,
      platform: "tiktok"
    )
    
    assert_not daily_stat.valid?
    assert_includes daily_stat.errors[:date], "can't be blank"
  end
  
  test "should require platform" do
    daily_stat = DailyStat.new(
      subscription: @subscription,
      date: Date.current,
      views: 1000,
      followers: 500,
      revenue: 50.25
    )
    
    assert_not daily_stat.valid?
    assert_includes daily_stat.errors[:platform], "can't be blank"
  end
  
  test "should require non-negative views" do
    daily_stat = DailyStat.new(
      subscription: @subscription,
      date: Date.current,
      views: -10,
      followers: 500,
      revenue: 50.25,
      platform: "tiktok"
    )
    
    assert_not daily_stat.valid?
    assert_includes daily_stat.errors[:views], "must be greater than or equal to 0"
  end
  
  test "should require non-negative followers" do
    daily_stat = DailyStat.new(
      subscription: @subscription,
      date: Date.current,
      views: 1000,
      followers: -10,
      revenue: 50.25,
      platform: "tiktok"
    )
    
    assert_not daily_stat.valid?
    assert_includes daily_stat.errors[:followers], "must be greater than or equal to 0"
  end
  
  test "should require non-negative revenue" do
    daily_stat = DailyStat.new(
      subscription: @subscription,
      date: Date.current,
      views: 1000,
      followers: 500,
      revenue: -10.25,
      platform: "tiktok"
    )
    
    assert_not daily_stat.valid?
    assert_includes daily_stat.errors[:revenue], "must be greater than or equal to 0"
  end
  
  test "should calculate total views" do
    # Create multiple daily stats
    DailyStat.create!(
      subscription: @subscription,
      date: 1.day.ago,
      views: 1000,
      followers: 500,
      revenue: 50.25,
      platform: "tiktok"
    )
    
    DailyStat.create!(
      subscription: @subscription,
      date: Date.current,
      views: 2000,
      followers: 600,
      revenue: 75.50,
      platform: "tiktok"
    )
    
    assert_equal 3000, DailyStat.total_views
  end
  
  test "should get latest followers" do
    # Create multiple daily stats with increasing follower counts
    DailyStat.create!(
      subscription: @subscription,
      date: 2.days.ago,
      views: 1000,
      followers: 500,
      revenue: 50.25,
      platform: "tiktok"
    )
    
    DailyStat.create!(
      subscription: @subscription,
      date: 1.day.ago,
      views: 2000,
      followers: 600,
      revenue: 75.50,
      platform: "tiktok"
    )
    
    DailyStat.create!(
      subscription: @subscription,
      date: Date.current,
      views: 3000,
      followers: 700,
      revenue: 100.75,
      platform: "tiktok"
    )
    
    assert_equal 700, DailyStat.total_followers
  end
end

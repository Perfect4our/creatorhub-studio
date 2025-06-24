require 'test_helper'

class SnapshotStatsJobTest < ActiveJob::TestCase
  test "job processes active subscriptions" do
    # Create a test subscription
    user = users(:one)
    subscription = Subscription.create!(
      user: user,
      tiktok_uid: "test_uid_#{Time.now.to_i}",
      auth_token: "test_token",
      platform: "tiktok",
      active: true
    )
    
    # Mock the service class
    mock_service = Minitest::Mock.new
    mock_service.expect(:sync!, true)
    
    # Stub the service class instantiation
    TiktokService.stub :new, mock_service do
      # Run the job
      SnapshotStatsJob.perform_now
    end
    
    # Verify the mock was called
    assert_mock mock_service
  end
  
  test "job skips inactive subscriptions" do
    # Create an inactive test subscription
    user = users(:one)
    subscription = Subscription.create!(
      user: user,
      tiktok_uid: "test_uid_inactive_#{Time.now.to_i}",
      auth_token: "test_token",
      platform: "tiktok",
      active: false
    )
    
    # Mock the service class that should not be called
    mock_service = Minitest::Mock.new
    # No expectations set, so it should not be called
    
    # Stub the service class instantiation
    TiktokService.stub :new, mock_service do
      # Run the job
      SnapshotStatsJob.perform_now
    end
    
    # Verify the mock was not called (no expectations, so it passes)
    assert_mock mock_service
  end
end

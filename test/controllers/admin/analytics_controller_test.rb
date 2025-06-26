require "test_helper"

class Admin::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = users(:admin_user) # Assuming we have an admin user in fixtures
    @regular_user = users(:one) # Regular user from fixtures
  end

  test "should redirect regular user from admin analytics" do
    sign_in @regular_user
    get admin_analytics_path
    assert_redirected_to root_path
    assert_match /Access denied/, flash[:alert]
  end

  test "should allow admin user to access analytics" do
    # Create an admin user for testing
    admin = User.create!(
      email: 'perfect4ouryt@gmail.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    sign_in admin
    get admin_analytics_path
    assert_response :success
    assert_match /Live Analytics/, response.body
  end

  test "should show proper analytics data for admin" do
    admin = User.create!(
      email: 'perfect4ouryt@gmail.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    sign_in admin
    get admin_analytics_path
    
    assert_response :success
    assert_select 'h1', text: /Live Analytics/
    assert_select '.admin-metric-value'
    assert_select '#signupsChart'
    assert_select '#activityFeed'
  end

  test "should redirect unauthenticated user" do
    get admin_analytics_path
    assert_redirected_to new_user_session_path
  end
end 
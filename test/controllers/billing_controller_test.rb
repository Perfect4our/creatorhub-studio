require "test_helper"

class BillingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = users(:one)
    sign_in @user
  end
  
  test "should get pricing page" do
    get pricing_path
    assert_response :success
    assert_select "h1", text: "Choose Your Plan"
  end
  
  test "should redirect to pricing with alert when stripe not configured" do
    post create_checkout_session_path, params: { plan: "monthly" }
    assert_redirected_to pricing_path
    follow_redirect!
    assert_match /Stripe is not configured/, response.body
  end
  
  test "should redirect when invalid plan selected" do
    post create_checkout_session_path, params: { plan: "invalid" }
    assert_redirected_to pricing_path
    follow_redirect!
    assert_match /Invalid plan/, response.body
  end
  
  test "pricing page shows setup notice when stripe not configured" do
    get pricing_path
    assert_response :success
    assert_select ".alert-warning", text: /Stripe Setup Required/
  end
end 
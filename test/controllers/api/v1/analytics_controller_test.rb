require "test_helper"

class Api::V1::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_analytics_index_url
    assert_response :success
  end
end

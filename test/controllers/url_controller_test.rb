require "test_helper"

class UrlControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get url_show_url
    assert_response :success
  end
end

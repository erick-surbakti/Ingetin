require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "shows the dashboard to a signed in owner" do
    sign_in_as users(:one)

    get root_path
    assert_response :success
    assert_select "h1", /Bu Sari/
  end
end

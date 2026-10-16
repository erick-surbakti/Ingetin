require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "shows counts for the signed in owner" do
    sign_in_as users(:one)

    get root_path
    assert_response :success
    assert_select "h1", /Bu Sari/
    assert_select "#property_count", "1"
    assert_select "#room_count", "3"
    assert_select "#active_tenant_count", "1"
  end

  test "shows an empty state for a new owner" do
    owner = User.create!(name: "Baru", email_address: "baru@example.com", password: "rahasia123")
    sign_in_as owner

    get root_path
    assert_select "a[href='#{new_property_path}']"
  end
end

require "test_helper"

class PaymentSettingsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get edit_payment_settings_path
    assert_redirected_to new_session_path
  end

  test "edit shows connection status and notification url without the key" do
    sign_in_as users(:two)

    get edit_payment_settings_path

    assert_response :success
    assert_select "#midtrans_status", /terhubung/
    assert_select "#notification_url", midtrans_webhook_url
    assert_no_match "twoTestKey456", response.body
  end

  test "saves the server key and admin fee" do
    sign_in_as users(:one)

    patch payment_settings_path, params: { user: { midtrans_server_key: "SB-Mid-server-BaruSekali99", va_admin_fee: "4.000" } }

    assert_redirected_to edit_payment_settings_path
    user = users(:one).reload
    assert_equal "SB-Mid-server-BaruSekali99", user.midtrans_server_key
    assert_equal 4_000, user.va_admin_fee
  end

  test "blank key keeps the stored key" do
    sign_in_as users(:two)

    patch payment_settings_path, params: { user: { midtrans_server_key: "", va_admin_fee: "5000" } }

    assert_equal "SB-Mid-server-twoTestKey456", users(:two).reload.midtrans_server_key
  end

  test "rejects an invalid key" do
    sign_in_as users(:one)

    patch payment_settings_path, params: { user: { midtrans_server_key: "client-key-salah" } }

    assert_response :unprocessable_content
    assert_nil users(:one).reload.midtrans_server_key
  end
end

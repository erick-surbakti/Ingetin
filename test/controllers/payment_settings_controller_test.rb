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

  test "guide shows step progress for a connected owner" do
    sign_in_as users(:two)

    get edit_payment_settings_path

    assert_select "#steps_done", "2/4 langkah"
    assert_select "#step_1[data-done=true]"
    assert_select "#step_3[data-done=false]"
    assert_select "#check_connection"
    assert_select "#key_mode_warning", count: 0
  end

  test "guide marks the notification and payment steps once they happen" do
    user = users(:two)
    user.update!(midtrans_notified_at: Time.current)
    invoice = invoices(:joko_october)
    invoice.payments.create!(order_id: "ING-#{invoice.id}-done0001", channel: "qris", gross_amount: 900_000,
      expires_at: 1.day.from_now, paid_at: Time.current)
    sign_in_as user

    get edit_payment_settings_path

    assert_select "#steps_done", "4/4 langkah"
  end

  test "warns when a sandbox key is used in production mode" do
    sign_in_as users(:two)

    previous = ENV["MIDTRANS_ENV"]
    ENV["MIDTRANS_ENV"] = "production"
    get edit_payment_settings_path

    assert_select "#key_mode_warning", /sandbox/
  ensure
    ENV["MIDTRANS_ENV"] = previous
  end

  test "connection check reports a valid key" do
    sign_in_as users(:two)

    post check_payment_settings_path

    assert_redirected_to edit_payment_settings_path(anchor: "panduan")
    assert_match "valid", flash[:notice]
  end

  test "connection check reports a rejected key" do
    sign_in_as users(:two)
    FakeMidtransClient.unauthorized = true

    post check_payment_settings_path

    assert_match "ditolak", flash[:alert]
  end

  test "connection check reports an unreachable Midtrans" do
    sign_in_as users(:two)
    FakeMidtransClient.fail_with = "timeout"

    post check_payment_settings_path

    assert_match "tidak bisa dihubungi", flash[:alert]
  end
end

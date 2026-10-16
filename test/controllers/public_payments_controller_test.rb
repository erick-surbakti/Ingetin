require "test_helper"

class PublicPaymentsControllerTest < ActionDispatch::IntegrationTest
  def pay(invoice, channel)
    post public_invoice_payments_path(invoice.public_token), params: { channel: channel }, as: :json
  end

  test "returns the Snap redirect url" do
    invoice = invoices(:joko_october)

    pay(invoice, "va")

    assert_response :success
    payment = invoice.payments.last
    assert_equal payment.redirect_url, response.parsed_body["redirect_url"]
    assert_equal 905_000, payment.gross_amount
    assert_nil FakeMidtransClient.snap_requests.last[:notification_url], "URL notifikasi http tidak dikirim"
    assert_equal public_invoice_url(invoice.public_token), FakeMidtransClient.snap_requests.last[:payload][:callbacks][:finish]
  end

  test "rejects unknown channels" do
    pay(invoices(:joko_october), "kartu")
    assert_response :unprocessable_content
  end

  test "rejects paid invoices" do
    pay(invoices(:rina_october), "qris")
    assert_response :conflict
  end

  test "explains when the owner has not connected Midtrans" do
    users(:two).update!(midtrans_server_key: nil)

    pay(invoices(:joko_october), "qris")

    assert_response :unprocessable_content
    assert_match "belum diaktifkan", response.parsed_body["error"]
  end

  test "reports Midtrans failures" do
    FakeMidtransClient.fail_with = "Snap HTTP 500"

    pay(invoices(:joko_october), "qris")

    assert_response :bad_gateway
  end

  test "unknown invoice token" do
    post public_invoice_payments_path("tidak-ada"), params: { channel: "qris" }, as: :json
    assert_response :not_found
  end
end

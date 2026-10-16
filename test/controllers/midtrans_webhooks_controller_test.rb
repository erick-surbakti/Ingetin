require "test_helper"

class MidtransWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invoice = invoices(:joko_october)
    @payment = @invoice.payments.create!(order_id: "ING-#{@invoice.id}-hook0001", channel: "qris",
      gross_amount: 900_000, expires_at: 1.day.from_now)
    @server_key = users(:two).midtrans_server_key
  end

  def notification(status_code: "200", gross_amount: "900000.00", signature: nil, order_id: @payment.order_id)
    {
      "order_id" => order_id,
      "status_code" => status_code,
      "gross_amount" => gross_amount,
      "transaction_status" => "settlement",
      "transaction_id" => "tx-#{order_id}",
      "signature_key" => signature || midtrans_signature(order_id, status_code, gross_amount, @server_key)
    }
  end

  def deliver(payload)
    post midtrans_webhook_path, params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  test "verified notification marks the invoice paid after confirming status" do
    FakeMidtransClient.settle!(@payment)

    deliver(notification)

    assert_response :ok
    assert @invoice.reload.paid?
    assert_equal "qris", @invoice.paid_via
  end

  test "duplicate notifications are processed once" do
    FakeMidtransClient.settle!(@payment)

    2.times { deliver(notification) }

    assert_response :ok
    assert_equal 1, Payment.where(midtrans_transaction_id: "tx-#{@payment.order_id}").count
    assert @invoice.reload.paid?
  end

  test "invalid signature is rejected" do
    FakeMidtransClient.settle!(@payment)

    deliver(notification(signature: "palsu"))

    assert_response :unauthorized
    assert @invoice.reload.unpaid?
  end

  test "signature made with another owner's key is rejected" do
    FakeMidtransClient.settle!(@payment)
    forged = midtrans_signature(@payment.order_id, "200", "900000.00", "SB-Mid-server-kunciLain")

    deliver(notification(signature: forged))

    assert_response :unauthorized
    assert @invoice.reload.unpaid?
  end

  test "a forged settlement is not trusted without Midtrans confirming it" do
    # Status di Midtrans masih pending walau notifikasi mengaku settlement.
    FakeMidtransClient.settle!(@payment, status: "pending")

    deliver(notification)

    assert_response :ok
    assert @invoice.reload.unpaid?
  end

  test "unknown order is acknowledged and ignored" do
    deliver(notification(order_id: "ORDER-LAIN-1"))
    assert_response :ok
  end

  test "malformed body is a bad request" do
    post midtrans_webhook_path, params: "{bukan json", headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end

  test "asks Midtrans to retry when the status API is unreachable" do
    FakeMidtransClient.fail_with = "timeout"

    deliver(notification)

    assert_response :service_unavailable
    assert @invoice.reload.unpaid?
  end
end

require "test_helper"

class PublicInvoicesControllerTest < ActionDispatch::IntegrationTest
  test "shows an unpaid invoice without login" do
    invoice = invoices(:joko_october)

    get public_invoice_path(invoice.public_token)

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "h1", "Tagihan sewa"
    assert_select "#amount", "Rp900.000"
    assert_select "#payment_options"
    assert_select "#pay_qris", /Rp900.000/
    assert_select "#pay_va", /Rp905.000/
  end

  test "explains when online payment is not available" do
    users(:two).update!(midtrans_server_key: nil)

    get public_invoice_path(invoices(:joko_october).public_token)

    assert_select "#payment_options", count: 0
    assert_select "#payment_unavailable"
  end

  test "returning from Snap syncs the payment and shows the receipt" do
    invoice = invoices(:joko_october)
    payment = invoice.payments.create!(order_id: "ING-#{invoice.id}-back0001", channel: "qris",
      gross_amount: 900_000, expires_at: 1.day.from_now)
    FakeMidtransClient.settle!(payment)

    get public_invoice_path(invoice.public_token, order_id: payment.order_id, transaction_status: "settlement")

    assert_select "h1", "Kuitansi pembayaran"
    assert invoice.reload.paid?
  end

  test "returning from Snap before settlement shows a processing notice" do
    invoice = invoices(:joko_october)
    payment = invoice.payments.create!(order_id: "ING-#{invoice.id}-back0002", channel: "va",
      gross_amount: 905_000, expires_at: 1.day.from_now)
    FakeMidtransClient.settle!(payment, status: "pending")

    get public_invoice_path(invoice.public_token, order_id: payment.order_id)

    assert_select "#processing"
    assert invoice.reload.unpaid?
  end

  test "shows a receipt once paid" do
    get public_invoice_path(invoices(:rina_october).public_token)

    assert_response :success
    assert_select "h1", "Kuitansi pembayaran"
    assert_select "#paid_at"
    assert_select "#payment_options", count: 0
  end

  test "unknown token is not found" do
    get public_invoice_path("tidak-ada")
    assert_response :not_found
  end
end

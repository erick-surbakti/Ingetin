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

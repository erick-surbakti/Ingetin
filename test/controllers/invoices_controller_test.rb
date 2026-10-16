require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:two) }

  test "index shows the selected month for the owner only" do
    get invoices_path(month: "2026-10")
    assert_response :success
    assert_select "#selected_month", "Oktober 2026"
    assert_select "##{dom_id(invoices(:joko_october))}"
    assert_select "##{dom_id(invoices(:rina_october))}", count: 0
    assert_select "#unpaid_count", "1"
    assert_select "#outstanding_total", "Rp900.000"
  end

  test "index falls back to the current month on a bad month param" do
    travel_to Time.zone.local(2026, 10, 20, 9) do
      get invoices_path(month: "bukan-bulan")
      assert_select "#selected_month", "Oktober 2026"
    end
  end

  test "generate creates due invoices for the owner's tenants only" do
    travel_to Time.zone.local(2026, 11, 28, 9) do
      assert_difference -> { Invoice.count }, 1 do
        post generate_invoices_path
      end
    end
    assert_redirected_to invoices_path
    assert tenants(:joko).invoices.exists?(period: Date.new(2026, 11, 1))
    assert_not tenants(:rina).invoices.exists?(period: Date.new(2026, 11, 1))
  end

  test "send_whatsapp counts the send and redirects to wa.me" do
    invoice = invoices(:joko_october)

    post send_whatsapp_invoice_path(invoice)

    assert_response :redirect
    assert response.location.start_with?("https://wa.me/6285700000000?text=")
    assert_includes CGI.unescape(response.location), public_invoice_url(invoice.public_token)
    assert_equal 1, invoice.reload.sent_count
  end

  test "mark_paid records a cash payment" do
    invoice = invoices(:joko_october)

    patch mark_paid_invoice_path(invoice)

    assert_redirected_to invoices_path(month: "2026-10")
    invoice.reload
    assert invoice.paid?
    assert_equal "cash", invoice.paid_via
  end

  test "another owner's invoice is not accessible" do
    other = invoices(:rina_october)

    post send_whatsapp_invoice_path(other)
    assert_response :not_found

    patch mark_paid_invoice_path(other)
    assert_response :not_found
  end
end

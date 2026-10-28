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

  test "index filters invoices by status tab" do
    joko = "##{dom_id(invoices(:joko_october))}"

    travel_to Time.zone.local(2026, 10, 20, 9) do
      get invoices_path(month: "2026-10", status: "pending")
      assert_select joko
      get invoices_path(month: "2026-10", status: "paid")
      assert_select joko, count: 0
      get invoices_path(month: "2026-10", status: "overdue")
      assert_select joko, count: 0
      get invoices_path(month: "2026-10", status: "bukan-status")
      assert_select joko
    end

    travel_to Time.zone.local(2026, 11, 5, 9) do
      get invoices_path(month: "2026-10", status: "overdue")
      assert_select joko
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

  test "send button opens wa.me with the message and public link" do
    invoice = invoices(:joko_october)

    get invoices_path(month: "2026-10")

    link = css_select("##{dom_id(invoice)} a[href^='https://wa.me/6285700000000?text=']").first
    assert link, "tombol Kirim WA tidak ditemukan"
    assert_includes CGI.unescape(link["href"]), public_invoice_url(invoice.public_token)
    assert_equal mark_sent_invoice_path(invoice), link["data-track-send-url-value"]
  end

  test "mark_sent counts sends" do
    invoice = invoices(:joko_october)

    post mark_sent_invoice_path(invoice)

    assert_response :no_content
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

    post mark_sent_invoice_path(other)
    assert_response :not_found

    patch mark_paid_invoice_path(other)
    assert_response :not_found
  end

  test "csv export downloads the owner's invoices for the month" do
    get invoices_path(format: :csv, month: "2026-10")

    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.media_type + "; charset=" + response.charset
    assert_match 'attachment; filename="ingetin-tagihan-2026-10.csv"', response.headers["Content-Disposition"]
    body = response.body.dup.force_encoding("UTF-8")
    assert_includes body, invoices(:joko_october).number
    assert_not_includes body, invoices(:rina_october).number
  end

  test "csv export respects the status tab" do
    travel_to Time.zone.local(2026, 10, 20, 9) do
      get invoices_path(format: :csv, month: "2026-10", status: "paid")
    end

    assert_match "ingetin-tagihan-2026-10-lunas.csv", response.headers["Content-Disposition"]
    assert_not_includes response.body.dup.force_encoding("UTF-8"), invoices(:joko_october).number
  end

  test "index shows the csv button only when the month has invoices" do
    get invoices_path(month: "2026-10")
    assert_select "#export_csv[href=?]", invoices_path(format: :csv, month: "2026-10")

    get invoices_path(month: "2026-01")
    assert_select "#export_csv", count: 0
  end

  test "csv export requires login" do
    sign_out
    get invoices_path(format: :csv, month: "2026-10")
    assert_redirected_to new_session_path
  end
end

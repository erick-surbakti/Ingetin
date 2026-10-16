require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  test "one invoice per tenant per period" do
    duplicate = tenants(:rina).invoices.new(period: Date.new(2026, 10, 1), due_on: Date.new(2026, 10, 10),
      amount: 1, description: "x")
    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:tenant_id, :taken)
  end

  test "overdue only when unpaid and past due" do
    invoice = invoices(:joko_october)
    assert_not invoice.overdue?(Date.new(2026, 10, 31))
    assert invoice.overdue?(Date.new(2026, 11, 1))
    assert_not invoices(:rina_october).overdue?(Date.new(2027, 1, 1))
  end

  test "mark_paid! records method and time once" do
    invoice = invoices(:joko_october)
    paid_at = Time.zone.local(2026, 10, 30, 14)

    assert invoice.mark_paid!(via: "qris", at: paid_at)
    assert invoice.reload.paid?
    assert_equal "qris", invoice.paid_via
    assert_equal paid_at, invoice.paid_at

    assert_equal false, invoice.mark_paid!(via: "cash")
    assert_equal "qris", invoice.reload.paid_via
  end

  test "mark_sent! counts sends" do
    invoice = invoices(:joko_october)
    2.times { invoice.mark_sent! }
    assert_equal 2, invoice.reload.sent_count
    assert invoice.last_sent_at.present?
  end

  test "number" do
    invoice = invoices(:joko_october)
    assert_equal "INV-202610-#{invoice.id.to_s.rjust(5, "0")}", invoice.number
  end
end

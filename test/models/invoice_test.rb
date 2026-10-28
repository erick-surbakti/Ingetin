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

  test "add and remove items change the total and keep the rent" do
    invoice = invoices(:joko_october)

    listrik = invoice.add_item!(name: "Listrik", amount: 75_000)
    invoice.add_item!(name: "Air", amount: 20_000)
    assert_equal 995_000, invoice.reload.amount
    assert_equal 900_000, invoice.rent_amount

    invoice.remove_item!(listrik)
    assert_equal 920_000, invoice.reload.amount
    assert_equal [ "Air" ], invoice.items.map(&:name)
  end

  test "items are locked once paid or while a virtual account payment is pending" do
    paid = invoices(:rina_october)
    assert_equal "Tagihan sudah lunas.", paid.items_locked_reason
    assert_raises(Invoice::Locked) { paid.add_item!(name: "Air", amount: 20_000) }

    invoice = invoices(:joko_october)
    invoice.payments.create!(order_id: "ING-#{invoice.id}-pend0001", channel: "va", status: "pending",
      gross_amount: 905_000, admin_fee: 5_000, expires_at: 1.day.from_now)
    assert_raises(Invoice::Locked) { invoice.add_item!(name: "Air", amount: 20_000) }
    assert_equal 900_000, invoice.reload.amount
  end

  test "changing items supersedes Snap transactions with the old amount" do
    invoice = invoices(:joko_october)
    open_payment = invoice.payments.create!(order_id: "ING-#{invoice.id}-open0001", channel: "qris",
      gross_amount: 900_000, expires_at: 1.day.from_now)

    invoice.add_item!(name: "Laundry", amount: 50_000)

    assert_equal "superseded", open_payment.reload.status
  end
end

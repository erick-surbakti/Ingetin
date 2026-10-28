require "test_helper"

class PaymentSyncTest < ActiveSupport::TestCase
  setup do
    @invoice = invoices(:joko_october)
    @payment = @invoice.payments.create!(order_id: "ING-#{@invoice.id}-sync0001", channel: "va",
      gross_amount: 905_000, admin_fee: 5_000, expires_at: 1.day.from_now)
  end

  test "settlement marks the invoice paid with the settlement time" do
    FakeMidtransClient.settle!(@payment, settlement_time: "2026-10-30 14:05:00")

    PaymentSync.new(@payment).call

    @payment.reload
    assert_equal "settlement", @payment.status
    assert_equal "tx-#{@payment.order_id}", @payment.midtrans_transaction_id
    assert_equal Time.zone.local(2026, 10, 30, 14, 5), @payment.paid_at

    @invoice.reload
    assert @invoice.paid?
    assert_equal "bank_transfer", @invoice.paid_via
    assert_equal Time.zone.local(2026, 10, 30, 14, 5), @invoice.paid_at
  end

  test "repeated syncs are idempotent" do
    FakeMidtransClient.settle!(@payment)
    PaymentSync.new(@payment).call
    paid_at = @invoice.reload.paid_at

    FakeMidtransClient.settle!(@payment, settlement_time: "2026-11-02 08:00:00")
    PaymentSync.new(@payment.reload).call

    assert_equal paid_at, @invoice.reload.paid_at
  end

  test "pending and expired statuses do not mark the invoice paid" do
    FakeMidtransClient.settle!(@payment, status: "pending")
    PaymentSync.new(@payment).call
    assert_equal "pending", @payment.reload.status
    assert @invoice.reload.unpaid?

    FakeMidtransClient.settle!(@payment, status: "expire")
    PaymentSync.new(@payment).call
    assert_equal "expire", @payment.reload.status
    assert @invoice.reload.unpaid?
  end

  test "ignores status data with a different amount" do
    FakeMidtransClient.settle!(@payment)
    FakeMidtransClient.statuses[@payment.order_id]["gross_amount"] = "1.00"

    PaymentSync.new(@payment).call

    assert_nil @payment.reload.paid_at
    assert @invoice.reload.unpaid?
  end

  test "unknown order at Midtrans leaves the payment untouched" do
    PaymentSync.new(@payment).call
    assert_equal "created", @payment.reload.status
  end

  test "a settlement for an outdated amount does not mark the invoice paid" do
    @invoice.update!(amount: 975_000)
    FakeMidtransClient.settle!(@payment)

    PaymentSync.new(@payment).call

    assert @payment.reload.paid_at.present?
    assert @invoice.reload.unpaid?
  end
end

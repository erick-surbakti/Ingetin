require "test_helper"

class PaymentCheckoutTest < ActiveSupport::TestCase
  setup { @invoice = invoices(:joko_october) }

  def checkout(channel, invoice: @invoice)
    PaymentCheckout.new(invoice, channel: channel, finish_url: "https://ingetin.test/t/x",
      notification_url: "https://ingetin.test/webhooks/midtrans").call
  end

  test "qris charges the rent only" do
    payment = checkout("qris")

    assert_equal 900_000, payment.gross_amount
    assert_equal 0, payment.admin_fee
    assert payment.order_id.start_with?("ING-#{@invoice.id}-")
    assert_equal "https://app.sandbox.midtrans.com/snap/v4/redirection/snap-#{payment.order_id}", payment.redirect_url

    request = FakeMidtransClient.snap_requests.last
    assert_equal "SB-Mid-server-twoTestKey456", request[:server_key]
    assert_equal "https://ingetin.test/webhooks/midtrans", request[:notification_url]
    assert_equal %w[ other_qris ], request[:payload][:enabled_payments]
    assert_equal({ order_id: payment.order_id, gross_amount: 900_000 }, request[:payload][:transaction_details])
    assert_equal "https://ingetin.test/t/x", request[:payload][:callbacks][:finish]
  end

  test "virtual account adds the owner's admin fee as a separate item" do
    users(:two).update!(va_admin_fee: 4_000)
    payment = checkout("va")

    assert_equal 904_000, payment.gross_amount
    assert_equal 4_000, payment.admin_fee

    payload = FakeMidtransClient.snap_requests.last[:payload]
    assert_includes payload[:enabled_payments], "bca_va"
    assert_equal payment.gross_amount, payload[:item_details].sum { |item| item[:price] * item[:quantity] }
    assert_equal "Biaya admin Virtual Account", payload[:item_details].last[:name]
    assert payload[:item_details].all? { |item| item[:name].length <= 50 }
  end

  test "reuses an open payment for the same channel" do
    first = checkout("va")
    assert_equal first, checkout("va")
    assert_equal 1, FakeMidtransClient.snap_requests.size

    assert_not_equal first, checkout("qris")
  end

  test "does not reuse an expired payment" do
    first = checkout("qris")
    first.update!(expires_at: 1.minute.ago)

    assert_not_equal first, checkout("qris")
  end

  test "refuses paid invoices and owners without Midtrans" do
    assert_raises(PaymentCheckout::NotPayable) { checkout("qris", invoice: invoices(:rina_october)) }

    users(:two).update!(midtrans_server_key: nil)
    assert_raises(PaymentCheckout::NotConfigured) { checkout("qris") }
  end

  test "marks the attempt failed when Snap rejects it" do
    FakeMidtransClient.fail_with = "Snap HTTP 401"

    assert_raises(Midtrans::Error) { checkout("qris") }
    assert_equal "failure", @invoice.payments.last.status
  end

  test "item details list the rent and extra charges and add up to the gross amount" do
    @invoice.add_item!(name: "Listrik", amount: 75_000)
    users(:two).update!(va_admin_fee: 4_000)

    payment = checkout("va")

    assert_equal 979_000, payment.gross_amount
    items = FakeMidtransClient.snap_requests.last[:payload][:item_details]
    assert_equal [ 900_000, 75_000, 4_000 ], items.map { |item| item[:price] }
    assert_equal "Listrik", items.second[:name]
    assert_equal payment.gross_amount, items.sum { |item| item[:price] * item[:quantity] }
  end

  test "does not reuse a pending payment created for an older amount" do
    first = checkout("va")
    first.update!(status: "pending")
    @invoice.update!(amount: 950_000)

    second = checkout("va")
    assert_not_equal first, second
    assert_equal 955_000, second.gross_amount
  end
end

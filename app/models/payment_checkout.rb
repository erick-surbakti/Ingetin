# Membuat (atau memakai ulang) transaksi Snap untuk satu metode bayar.
# QRIS: nominal sewa. VA: nominal sewa + biaya admin VA (dibayar penghuni).
class PaymentCheckout
  class NotPayable < StandardError; end
  class NotConfigured < StandardError; end

  REUSE_WINDOW = 23.hours

  def initialize(invoice, channel:, finish_url:, notification_url: nil)
    @invoice = invoice
    @channel = channel
    @finish_url = finish_url
    @notification_url = notification_url
  end

  def call
    raise NotPayable if @invoice.paid?

    owner = @invoice.tenant.room.property.user
    raise NotConfigured unless owner.midtrans_connected?

    reusable_payment || create_payment(owner)
  end

  private
    # Hanya transaksi dengan nominal tagihan saat ini; nominal bisa berubah
    # setelah pemilik menambah biaya tambahan.
    def reusable_payment
      @invoice.payments
        .where(channel: @channel, status: %w[ created pending ])
        .where(expires_at: Time.current..)
        .where.not(redirect_url: nil)
        .order(created_at: :desc)
        .detect { |payment| payment.gross_amount == @invoice.amount + payment.admin_fee }
    end

    def create_payment(owner)
      admin_fee = @channel == "va" ? owner.va_admin_fee : 0
      payment = @invoice.payments.create!(
        channel: @channel,
        order_id: Payment.generate_order_id(@invoice),
        gross_amount: @invoice.amount + admin_fee,
        admin_fee: admin_fee,
        expires_at: REUSE_WINDOW.from_now
      )

      response = Midtrans.client_for(owner).create_snap_transaction(payload(payment), notification_url: @notification_url)
      payment.update!(snap_token: response["token"], redirect_url: response["redirect_url"])
      payment
    rescue Midtrans::Error
      payment&.update!(status: "failure")
      raise
    end

    def payload(payment)
      tenant = @invoice.tenant
      items = [ { id: "SEWA-#{@invoice.id}", price: @invoice.rent_amount, quantity: 1, name: @invoice.description.truncate(50) } ]
      @invoice.items.each do |item|
        items << { id: "ITEM-#{item.id}", price: item.amount, quantity: 1, name: item.name.truncate(50) }
      end
      if payment.admin_fee.positive?
        items << { id: "ADMIN-VA", price: payment.admin_fee, quantity: 1, name: "Biaya admin Virtual Account" }
      end

      {
        transaction_details: { order_id: payment.order_id, gross_amount: payment.gross_amount },
        item_details: items,
        customer_details: { first_name: tenant.name.truncate(50), phone: tenant.phone },
        enabled_payments: Payment::CHANNELS.fetch(@channel),
        callbacks: { finish: @finish_url }
      }
    end
end

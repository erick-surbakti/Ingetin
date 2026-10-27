# Menyamakan status Payment dengan Midtrans (Get Status API) dan menandai
# tagihan lunas saat transaksi settlement. Idempoten: notifikasi ganda atau
# sinkron berulang tidak mengubah apa pun setelah lunas.
class PaymentSync
  def initialize(payment)
    @payment = payment
  end

  def call
    data = Midtrans.client_for(@payment.owner).transaction_status(@payment.order_id)
    apply(data) unless data["status_code"].to_s == "404"
    @payment
  end

  private
    def apply(data)
      @payment.with_lock do
        if @payment.paid_at.present?
          # Sudah diproses sebelumnya.
        elsif !matches?(data)
          Rails.logger.warn("[Midtrans] Data status tidak cocok untuk #{@payment.order_id}: #{data.slice("order_id", "gross_amount")}")
        else
          record(data)
        end
      end
    end

    def matches?(data)
      data["order_id"] == @payment.order_id && data["gross_amount"].to_d == @payment.gross_amount
    end

    def record(data)
      @payment.update!(
        status: data["transaction_status"].to_s,
        midtrans_transaction_id: data["transaction_id"].presence || @payment.midtrans_transaction_id,
        payment_type: data["payment_type"],
        last_notification: data.to_json
      )
      return unless settled?(data)

      paid_at = Time.zone.parse(data["settlement_time"].to_s) || Time.current
      @payment.update!(paid_at: paid_at)

      invoice = @payment.invoice
      if @payment.gross_amount == invoice.amount + @payment.admin_fee
        invoice.mark_paid!(via: @payment.paid_via, at: paid_at)
      else
        # Nominal tagihan berubah (biaya tambahan) setelah transaksi ini dibuat.
        Rails.logger.warn("[Midtrans] #{@payment.order_id} dibayar #{@payment.gross_amount}, tagihan #{invoice.number} sekarang #{invoice.amount}; tidak ditandai lunas otomatis")
      end
    end

    def settled?(data)
      status = data["transaction_status"]
      fraud = data["fraud_status"]

      (status == "settlement" && (fraud.blank? || fraud == "accept")) ||
        (status == "capture" && fraud == "accept")
    end
end

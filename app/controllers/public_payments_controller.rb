# Dipanggil dari halaman tagihan penghuni saat menekan "Bayar QRIS" atau
# "Bayar Virtual Account". Mengembalikan URL halaman bayar Snap (JSON).
class PublicPaymentsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 1.minute,
    with: -> { render json: { error: "Terlalu banyak percobaan. Coba lagi sebentar lagi." }, status: :too_many_requests }

  def create
    invoice = Invoice.find_by!(public_token: params[:token])
    channel = params[:channel].to_s

    unless Payment::CHANNELS.key?(channel)
      return render json: { error: "Metode pembayaran tidak dikenal." }, status: :unprocessable_content
    end

    payment = PaymentCheckout.new(
      invoice,
      channel: channel,
      finish_url: public_invoice_url(invoice.public_token),
      notification_url: notification_url
    ).call

    render json: { redirect_url: payment.redirect_url }
  rescue PaymentCheckout::NotPayable
    render json: { error: "Tagihan ini sudah lunas." }, status: :conflict
  rescue PaymentCheckout::NotConfigured
    render json: { error: "Pembayaran online belum diaktifkan pemilik kos." }, status: :unprocessable_content
  rescue Midtrans::Error => e
    Rails.logger.error("[Midtrans] Gagal membuat transaksi: #{e.message}")
    render json: { error: "Gagal membuat pembayaran. Coba lagi sebentar lagi." }, status: :bad_gateway
  end

  private
    # Midtrans hanya menerima URL notifikasi HTTPS.
    def notification_url
      url = midtrans_webhook_url
      url if url.start_with?("https://")
    end
end

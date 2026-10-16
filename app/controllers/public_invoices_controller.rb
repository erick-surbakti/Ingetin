class PublicInvoicesController < ApplicationController
  allow_unauthenticated_access

  def show
    @invoice = Invoice.includes(tenant: { room: { property: :user } }).find_by!(public_token: params[:token])
    sync_after_payment if params[:order_id].present? && @invoice.unpaid?
    response.set_header("X-Robots-Tag", "noindex, nofollow")
  end

  private
    # Snap mengarahkan penghuni kembali ke sini dengan ?order_id=...
    # Cek status langsung supaya kuitansi tampil tanpa menunggu webhook.
    def sync_after_payment
      payment = @invoice.payments.find_by(order_id: params[:order_id].to_s)
      return unless payment

      PaymentSync.new(payment).call
      @invoice.reload
      @processing = @invoice.unpaid?
    rescue Midtrans::Error => e
      Rails.logger.warn("[Midtrans] Sinkron saat kembali dari Snap gagal: #{e.message}")
      @processing = true
    end
end

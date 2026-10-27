# HTTP notification Midtrans. Tanda tangan diverifikasi dengan server key
# pemilik tagihan, lalu status diambil ulang dari Get Status API sebelum
# tagihan ditandai lunas.
class MidtransWebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection only: :create

  def create
    payload = JSON.parse(request.raw_post)
    payment = Payment.find_by(order_id: payload["order_id"].to_s)

    # Order bukan milik Ingetin (misalnya tes dari dashboard Midtrans).
    return head :ok unless payment

    unless Midtrans.valid_signature?(payload, server_key: payment.owner.midtrans_server_key)
      return head :unauthorized
    end

    owner = payment.owner
    owner.update_column(:midtrans_notified_at, Time.current) if owner.midtrans_notified_at.nil?

    PaymentSync.new(payment).call
    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue Midtrans::Error => e
    Rails.logger.error("[Midtrans] Gagal sinkron status: #{e.message}")
    # 503 membuat Midtrans mencoba ulang.
    head :service_unavailable
  end
end

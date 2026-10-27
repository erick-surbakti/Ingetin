# Pengganti Midtrans::Client di test: tidak ada request jaringan.
class FakeMidtransClient
  class << self
    attr_accessor :snap_requests, :statuses, :fail_with, :unauthorized

    def reset!
      self.snap_requests = []
      self.statuses = {}
      self.fail_with = nil
      self.unauthorized = false
    end

    def settle!(payment, transaction_id: "tx-#{payment.order_id}", settlement_time: "2026-10-30 14:05:00", status: "settlement")
      statuses[payment.order_id] = {
        "status_code" => "200",
        "order_id" => payment.order_id,
        "transaction_id" => transaction_id,
        "transaction_status" => status,
        "fraud_status" => "accept",
        "payment_type" => payment.channel == "qris" ? "qris" : "bank_transfer",
        "gross_amount" => "#{payment.gross_amount}.00",
        "settlement_time" => settlement_time
      }
    end
  end

  reset!

  def initialize(server_key:)
    @server_key = server_key
  end

  def create_snap_transaction(payload, notification_url: nil)
    raise Midtrans::Error, fail_with if self.class.fail_with

    self.class.snap_requests << { server_key: @server_key, payload: payload, notification_url: notification_url }
    order_id = payload.dig(:transaction_details, :order_id)
    { "token" => "snap-#{order_id}", "redirect_url" => "https://app.sandbox.midtrans.com/snap/v4/redirection/snap-#{order_id}" }
  end

  def transaction_status(order_id)
    raise Midtrans::Unauthorized, "Status API HTTP 401" if self.class.unauthorized
    raise Midtrans::Error, self.class.fail_with if self.class.fail_with

    self.class.statuses.fetch(order_id) { { "status_code" => "404" } }
  end

  private
    def fail_with
      self.class.fail_with
    end
end

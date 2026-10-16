# Integrasi Midtrans. Setiap pemilik kos memakai akun Midtrans miliknya sendiri,
# jadi semua request memakai server key pemilik tagihan.
module Midtrans
  class Error < StandardError; end

  # Diganti dengan client palsu di test.
  mattr_accessor :client_class, default: "Midtrans::Client"

  module_function

  def client_for(user)
    klass = client_class.is_a?(String) ? client_class.constantize : client_class
    klass.new(server_key: user.midtrans_server_key)
  end

  def environment
    ENV.fetch("MIDTRANS_ENV", "sandbox")
  end

  def production?
    environment == "production"
  end

  def snap_url
    production? ? "https://app.midtrans.com/snap/v1/transactions" : "https://app.sandbox.midtrans.com/snap/v1/transactions"
  end

  def api_base_url
    production? ? "https://api.midtrans.com" : "https://api.sandbox.midtrans.com"
  end

  # SHA512(order_id + status_code + gross_amount + server_key)
  def valid_signature?(payload, server_key:)
    expected = ::Digest::SHA512.hexdigest(
      "#{payload["order_id"]}#{payload["status_code"]}#{payload["gross_amount"]}#{server_key}"
    )
    ActiveSupport::SecurityUtils.secure_compare(expected, payload["signature_key"].to_s)
  end
end

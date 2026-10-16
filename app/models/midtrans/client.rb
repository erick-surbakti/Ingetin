require "net/http"

module Midtrans
  class Client
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 15

    def initialize(server_key:)
      @server_key = server_key
    end

    # Membuat transaksi Snap. Mengembalikan { "token", "redirect_url" }.
    def create_snap_transaction(payload, notification_url: nil)
      headers = {}
      headers["X-Override-Notification"] = notification_url if notification_url.present?

      response = request(Net::HTTP::Post, URI(Midtrans.snap_url), body: payload.to_json, headers: headers)
      body = parse(response)

      unless response.code == "201" && body["token"].present?
        raise Error, "Snap HTTP #{response.code}: #{Array(body["error_messages"]).join(", ")}"
      end

      body
    end

    # Status transaksi dari Get Status API. Order yang belum dibayar/dipilih
    # metodenya menghasilkan status_code "404".
    def transaction_status(order_id)
      uri = URI("#{Midtrans.api_base_url}/v2/#{ERB::Util.url_encode(order_id)}/status")
      response = request(Net::HTTP::Get, uri)

      unless response.is_a?(Net::HTTPSuccess) || response.code == "404"
        raise Error, "Status API HTTP #{response.code}"
      end

      parse(response)
    end

    private
      def request(request_class, uri, body: nil, headers: {})
        request = request_class.new(uri)
        request.basic_auth(@server_key, "")
        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"
        headers.each { |name, value| request[name] = value }
        request.body = body if body

        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
          http.request(request)
        end
      rescue Timeout::Error, SystemCallError, SocketError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
        raise Error, "Midtrans tidak bisa dihubungi (#{e.class})"
      end

      def parse(response)
        JSON.parse(response.body.presence || "{}")
      rescue JSON::ParserError
        {}
      end
  end
end

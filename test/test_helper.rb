ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/fake_midtrans_client"

Midtrans.client_class = FakeMidtransClient

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup { FakeMidtransClient.reset! }

    def midtrans_signature(order_id, status_code, gross_amount, server_key)
      ::Digest::SHA512.hexdigest("#{order_id}#{status_code}#{gross_amount}#{server_key}")
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include ActionView::RecordIdentifier
end

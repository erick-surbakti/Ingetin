require "test_helper"

class GenerateInvoicesJobTest < ActiveJob::TestCase
  test "generates invoices due within three days" do
    travel_to Time.zone.local(2026, 11, 7, 1) do
      assert_difference -> { tenants(:rina).invoices.count }, 1 do
        GenerateInvoicesJob.perform_now
      end
    end
  end
end

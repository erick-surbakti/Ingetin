require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "summarises this month's invoices for the owner" do
    sign_in_as users(:two)

    travel_to Time.zone.local(2026, 11, 2, 9) do
      get root_path
    end

    assert_response :success
    assert_select "h1", /Pak Budi/
    assert_select "#paid_count", "0"
    assert_select "#unpaid_count", "0"
    assert_select "#all_paid", /Belum ada tagihan bulan ini/
  end

  test "lists unpaid invoices first" do
    sign_in_as users(:two)

    travel_to Time.zone.local(2026, 10, 20, 9) do
      get root_path
    end

    assert_select "#unpaid_count", "1"
    assert_select "#unpaid_invoices ##{dom_id(invoices(:joko_october))}"
  end

  test "shows paid totals" do
    sign_in_as users(:one)

    travel_to Time.zone.local(2026, 10, 20, 9) do
      get root_path
    end

    assert_select "#paid_count", "1"
    assert_select "#received_total", "Rp1.500.000"
    assert_select "#all_paid", /sudah lunas/
  end

  test "shows an empty state for a new owner" do
    owner = User.create!(name: "Baru", email_address: "baru@example.com", password: "rahasia123")
    sign_in_as owner

    get root_path
    assert_select "a[href='#{new_property_path}']"
  end
end

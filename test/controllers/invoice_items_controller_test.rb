require "test_helper"

class InvoiceItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:two)
    @invoice = invoices(:joko_october)
  end

  test "invoice detail shows the breakdown and the add form" do
    get invoice_path(@invoice)

    assert_response :success
    assert_select "#rent_amount", "Rp900.000"
    assert_select "#total_amount", "Rp900.000"
    assert_select "#add_item form"
  end

  test "adding an item raises the total" do
    post invoice_items_path(@invoice), params: { invoice_item: { name: "Listrik", amount: "75.000" } }

    assert_redirected_to invoice_path(@invoice)
    assert_equal 975_000, @invoice.reload.amount

    follow_redirect!
    assert_select "#total_amount", "Rp975.000"
    assert_select "##{dom_id(@invoice.items.first)}", /Listrik/
  end

  test "invalid items re-render the form with errors" do
    post invoice_items_path(@invoice), params: { invoice_item: { name: "", amount: "" } }

    assert_response :unprocessable_content
    assert_select "#form_errors"
    assert_equal 900_000, @invoice.reload.amount
  end

  test "removing an item lowers the total" do
    item = @invoice.add_item!(name: "Air", amount: 20_000)

    delete invoice_item_path(@invoice, item)

    assert_redirected_to invoice_path(@invoice)
    assert_equal 900_000, @invoice.reload.amount
  end

  test "paid invoices cannot get new items" do
    sign_in_as users(:one)
    paid = invoices(:rina_october)

    get invoice_path(paid)
    assert_select "#add_item", count: 0
    assert_select "#items_locked", /sudah lunas/

    post invoice_items_path(paid), params: { invoice_item: { name: "Air", amount: "20000" } }
    assert_redirected_to invoice_path(paid)
    assert_equal 1_500_000, paid.reload.amount
  end

  test "another owner's invoice is not accessible" do
    other = invoices(:rina_october)

    get invoice_path(other)
    assert_response :not_found

    post invoice_items_path(other), params: { invoice_item: { name: "Air", amount: "20000" } }
    assert_response :not_found
  end

  test "public invoice page lists extra charges" do
    @invoice.add_item!(name: "Listrik", amount: 75_000)

    get public_invoice_path(@invoice.public_token)

    assert_select "#amount", "Rp975.000"
    assert_select "#pay_qris", /Rp975.000/
    assert_select "li", /Listrik/
  end
end

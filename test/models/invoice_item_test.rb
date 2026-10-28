require "test_helper"

class InvoiceItemTest < ActiveSupport::TestCase
  setup { @invoice = invoices(:joko_october) }

  test "accepts formatted amounts and tidies the name" do
    item = @invoice.add_item!(name: "  Listrik   bulan ini ", amount: "75.000")

    assert item.persisted?
    assert_equal "Listrik bulan ini", item.name
    assert_equal 75_000, item.amount
  end

  test "rejects blank names and invalid amounts without changing the total" do
    [ { name: "", amount: "10000" }, { name: "Air", amount: "0" }, { name: "Air", amount: "abc" },
      { name: "Air", amount: (InvoiceItem::MAX_AMOUNT + 1).to_s } ].each do |attributes|
      item = @invoice.add_item!(**attributes)
      assert_not item.persisted?, attributes.inspect
    end

    assert_equal 900_000, @invoice.reload.amount
    assert_empty @invoice.items
  end
end

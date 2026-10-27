require "test_helper"

class InvoiceMessageTest < ActiveSupport::TestCase
  setup { @invoice = invoices(:joko_october) }

  test "billing message before due date" do
    message = InvoiceMessage.new(@invoice, link: "https://ingetin.test/t/abc", today: Date.new(2026, 10, 28))

    assert_includes message.text, "Halo Joko, berikut tagihan Sewa Kos Mawar kamar B1 Oktober 2026 sebesar Rp900.000, jatuh tempo 31 Oktober 2026."
    assert_includes message.text, "https://ingetin.test/t/abc"
    assert message.text.end_with?("Pak Budi")
  end

  test "reminder message after due date" do
    message = InvoiceMessage.new(@invoice, link: "https://ingetin.test/t/abc", today: Date.new(2026, 11, 2))
    assert_includes message.text, "mengingatkan tagihan"
    assert_includes message.text, "sudah lewat jatuh tempo (31 Oktober 2026)"
  end

  test "whatsapp url targets the tenant number with an encoded message" do
    message = InvoiceMessage.new(@invoice, link: "https://ingetin.test/t/abc", today: Date.new(2026, 10, 28))
    url = message.whatsapp_url

    assert url.start_with?("https://wa.me/6285700000000?text=Halo%20Joko%2C")
    assert_equal message.text, CGI.unescape(URI.parse(url).query.delete_prefix("text=").gsub("+", "%2B"))
  end

  test "mentions extra charges included in the total" do
    @invoice.add_item!(name: "Listrik", amount: 75_000)
    message = InvoiceMessage.new(@invoice, link: "https://ingetin.test/t/abc", today: Date.new(2026, 10, 28))

    assert_includes message.text, "sebesar Rp975.000 (termasuk Listrik Rp75.000), jatuh tempo"
  end
end

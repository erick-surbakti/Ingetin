require "test_helper"

class InvoiceCsvExportTest < ActiveSupport::TestCase
  setup do
    @month = Date.new(2026, 10, 1)
    @joko = invoices(:joko_october)
  end

  def rows(invoices, today: Date.new(2026, 10, 20), status: "all")
    csv = InvoiceCsvExport.new(invoices, month: @month, status: status, today: today).to_csv
    assert csv.start_with?(InvoiceCsvExport::BOM), "CSV harus diawali BOM untuk Excel"
    CSV.parse(csv.delete_prefix(InvoiceCsvExport::BOM), col_sep: ";")
  end

  test "header, one row per invoice, and a total row" do
    @joko.add_item!(name: "Listrik", amount: 75_000)
    header, row, total = rows([ @joko.reload ])

    assert_equal InvoiceCsvExport::HEADERS, header
    record = header.zip(row).to_h
    assert_equal "Oktober 2026", record["Periode"]
    assert_equal @joko.number, record["No. tagihan"]
    assert_equal "Kos Mawar", record["Properti"]
    assert_equal "Joko", record["Penghuni"]
    assert_equal "2026-10-31", record["Jatuh tempo"]
    assert_equal "900000", record["Sewa"]
    assert_equal "75000", record["Biaya tambahan"]
    assert_equal "Listrik 75000", record["Rincian biaya tambahan"]
    assert_equal "975000", record["Total"]
    assert_equal "Belum bayar", record["Status"]
    assert_nil record["Tanggal bayar"]

    assert_equal [ "TOTAL", "1 tagihan" ], total.first(2)
    assert_equal "975000", total[10]
  end

  test "paid and overdue statuses" do
    paid = invoices(:rina_october)
    paid_row = rows([ paid ])[1]
    assert_equal "Lunas", paid_row[11]
    # Fixture tersimpan 10:00 UTC; ditampilkan dalam WIB seperti di kuitansi.
    assert_equal "2026-10-09 17:00", paid_row[12]
    assert_equal "Tunai", paid_row[13]

    overdue_row = rows([ @joko ], today: Date.new(2026, 11, 3))[1]
    assert_equal "Telat", overdue_row[11]
  end

  test "text that Excel would run as a formula is neutralised" do
    tenants(:joko).update_columns(name: "=HYPERLINK(\"http://jahat\")")
    row = rows([ @joko.reload ])[1]

    assert_equal "'=HYPERLINK(\"http://jahat\")", row[4]
  end

  test "filename follows the month and status filter" do
    assert_equal "ingetin-tagihan-2026-10.csv", InvoiceCsvExport.new([], month: @month).filename
    assert_equal "ingetin-tagihan-2026-10-lunas.csv", InvoiceCsvExport.new([], month: @month, status: "paid").filename
    assert_equal "ingetin-tagihan-2026-10-telat.csv", InvoiceCsvExport.new([], month: @month, status: "overdue").filename
  end
end

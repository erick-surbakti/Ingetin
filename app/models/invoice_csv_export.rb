require "csv"

# Rekap tagihan satu bulan dalam CSV untuk dibuka di Excel: pemisah titik
# koma dan BOM UTF-8 (Excel berbahasa Indonesia), nominal berupa angka
# polos supaya bisa dijumlah.
class InvoiceCsvExport
  BOM = "﻿".freeze
  HEADERS = [
    "Periode", "No. tagihan", "Properti", "Kamar", "Penghuni", "No. WhatsApp", "Jatuh tempo",
    "Sewa", "Biaya tambahan", "Rincian biaya tambahan", "Total", "Status", "Tanggal bayar", "Metode",
    "Terakhir dikirim WA"
  ].freeze
  STATUS_SUFFIXES = { "pending" => "belum-bayar", "overdue" => "telat", "paid" => "lunas" }.freeze
  # Awalan yang dibaca Excel sebagai rumus (CSV injection).
  FORMULA_PREFIX = /\A[=+\-@\t\r]/

  def initialize(invoices, month:, status: "all", today: Date.current)
    @invoices = invoices
    @month = month
    @status = status
    @today = today
  end

  def to_csv
    BOM + CSV.generate(col_sep: ";") do |csv|
      csv << HEADERS
      @invoices.each { |invoice| csv << row(invoice) }
      csv << total_row
    end
  end

  def filename
    [ "ingetin-tagihan", @month.strftime("%Y-%m"), STATUS_SUFFIXES[@status] ].compact.join("-") + ".csv"
  end

  private
    def row(invoice)
      tenant = invoice.tenant
      room = tenant.room

      [
        I18n.l(invoice.period, format: :month),
        invoice.number,
        text(room.property.name),
        text(room.name),
        text(tenant.name),
        PhoneNumber.display(tenant.phone),
        invoice.due_on.iso8601,
        invoice.rent_amount,
        extras_total(invoice),
        text(invoice.items.map { |item| "#{item.name} #{item.amount}" }.join(", ").presence),
        invoice.amount,
        status_label(invoice),
        invoice.paid_at&.strftime("%Y-%m-%d %H:%M"),
        (Invoice::PAID_VIA_LABELS[invoice.paid_via] if invoice.paid?),
        last_sent(invoice)
      ]
    end

    def total_row
      rent = @invoices.sum(&:rent_amount)
      extras = @invoices.sum { |invoice| extras_total(invoice) }
      [ "TOTAL", "#{@invoices.size} tagihan", nil, nil, nil, nil, nil, rent, extras, nil, rent + extras ]
    end

    def extras_total(invoice)
      invoice.items.sum(&:amount)
    end

    def status_label(invoice)
      if invoice.paid?
        "Lunas"
      elsif invoice.overdue?(@today)
        "Telat"
      else
        "Belum bayar"
      end
    end

    def last_sent(invoice)
      return if invoice.sent_count.zero?

      "#{invoice.last_sent_at.strftime("%Y-%m-%d %H:%M")} (#{invoice.sent_count}x)"
    end

    # Teks bebas dari pengguna diberi awalan ' supaya tidak dijalankan
    # sebagai rumus oleh Excel.
    def text(value)
      value.to_s.match?(FORMULA_PREFIX) ? "'#{value}" : value
    end
end

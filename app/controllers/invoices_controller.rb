class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[ show mark_sent mark_paid ]

  def index
    @month = selected_month
    invoices = Current.user.invoices.for_period(@month).includes(:items, tenant: { room: { property: :user } })
    @summary = InvoiceSummary.new(invoices)
    @status = params[:status].presence_in(InvoiceSummary::FILTERS) || "all"
    @invoices = @summary.filtered(@status)
  end

  def show
    @item = InvoiceItem.new
  end

  def generate
    created = InvoiceGenerator.new(tenants: Current.user.tenants).call

    notice = if created.any?
      "#{created.size} tagihan baru dibuat."
    else
      "Tidak ada tagihan baru. Tagihan dibuat otomatis #{InvoiceGenerator::LEAD_DAYS} hari sebelum jatuh tempo."
    end
    redirect_to invoices_path, notice: notice
  end

  # Dipanggil di latar belakang saat tombol Kirim WA ditekan; link wa.me
  # sendiri dibuka langsung oleh browser.
  def mark_sent
    @invoice.mark_sent!
    head :no_content
  end

  def mark_paid
    if @invoice.mark_paid!(via: "cash")
      redirect_to invoices_path(month: month_param(@invoice.period)), notice: "Tagihan #{@invoice.tenant.name} dicatat lunas (tunai)."
    else
      redirect_to invoices_path(month: month_param(@invoice.period)), alert: "Tagihan ini sudah lunas."
    end
  end

  private
    def set_invoice
      @invoice = Current.user.invoices.find(params[:id])
    end

    def selected_month
      Date.strptime(params[:month].to_s, "%Y-%m")
    rescue Date::Error
      Date.current.beginning_of_month
    end

    def month_param(date)
      date.strftime("%Y-%m")
    end
end

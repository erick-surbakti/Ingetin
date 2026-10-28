# Biaya tambahan (listrik, air, laundry) di tagihan milik pemilik yang login.
class InvoiceItemsController < ApplicationController
  before_action :set_invoice

  def create
    attributes = params.expect(invoice_item: %i[ name amount ])
    @item = @invoice.add_item!(name: attributes[:name], amount: attributes[:amount])

    if @item.persisted?
      redirect_to invoice_path(@invoice), notice: "#{@item.name} ditambahkan. Total tagihan sekarang #{helpers.rupiah(@invoice.amount)}."
    else
      render "invoices/show", status: :unprocessable_content
    end
  rescue Invoice::Locked => e
    redirect_to invoice_path(@invoice), alert: "Biaya tambahan tidak bisa diubah. #{e.message}"
  end

  def destroy
    item = @invoice.items.find(params[:id])
    @invoice.remove_item!(item)
    redirect_to invoice_path(@invoice), notice: "#{item.name} dihapus. Total tagihan sekarang #{helpers.rupiah(@invoice.amount)}."
  rescue Invoice::Locked => e
    redirect_to invoice_path(@invoice), alert: "Biaya tambahan tidak bisa diubah. #{e.message}"
  end

  private
    def set_invoice
      @invoice = Current.user.invoices.find(params[:invoice_id])
    end
end

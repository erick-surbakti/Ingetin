module ApplicationHelper
  def nav_link(label, path)
    active = path == root_path ? current_page?(root_path) : request.path.start_with?(path)
    classes = active ? "bg-brand-50 text-brand-700" : "text-stone-600 hover:bg-stone-100"

    link_to label, path, class: "shrink-0 rounded-md px-3 py-1.5 #{classes}", aria: { current: (active ? "page" : nil) }
  end

  def rupiah(amount)
    number_to_currency(amount)
  end

  def phone_display(number)
    PhoneNumber.display(number)
  end

  def invoice_status_badge(invoice)
    label, classes =
      if invoice.paid?
        [ "Lunas", "bg-brand-50 text-brand-700" ]
      elsif invoice.overdue?
        [ "Telat", "bg-red-50 text-red-700" ]
      else
        [ "Belum bayar", "bg-amber-50 text-amber-800" ]
      end

    tag.span label, class: "inline-flex shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold #{classes}"
  end

  def paid_via_label(paid_via)
    { "cash" => "Tunai", "qris" => "QRIS", "bank_transfer" => "Virtual Account" }.fetch(paid_via.to_s, "-")
  end

  def whatsapp_url_for(invoice)
    InvoiceMessage.new(invoice, link: public_invoice_url(invoice.public_token)).whatsapp_url
  end
end

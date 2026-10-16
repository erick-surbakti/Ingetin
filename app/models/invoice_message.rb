# Pesan WhatsApp untuk mode "klik kirim": pemilik kos menekan tombol,
# WhatsApp terbuka dengan pesan + link bayar yang sudah terisi.
class InvoiceMessage
  include ActiveSupport::NumberHelper

  def initialize(invoice, link:, today: Date.current)
    @invoice = invoice
    @link = link
    @today = today
  end

  def text
    tenant = @invoice.tenant
    amount = number_to_currency(@invoice.amount)
    due = I18n.l(@invoice.due_on, format: :long)
    owner = tenant.room.property.user.name

    if @invoice.overdue?(@today)
      <<~TEXT.strip
        Halo #{tenant.name}, mengingatkan tagihan #{@invoice.description} sebesar #{amount} sudah lewat jatuh tempo (#{due}).

        Mohon dibayar lewat link berikut:
        #{@link}

        Terima kasih.
        #{owner}
      TEXT
    else
      <<~TEXT.strip
        Halo #{tenant.name}, berikut tagihan #{@invoice.description} sebesar #{amount}, jatuh tempo #{due}.

        Bayar lewat link berikut:
        #{@link}

        Terima kasih.
        #{owner}
      TEXT
    end
  end

  def whatsapp_url
    "https://wa.me/#{@invoice.tenant.phone}?text=#{ERB::Util.url_encode(text)}"
  end
end

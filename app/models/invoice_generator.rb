# Membuat tagihan bulanan H-3 sebelum jatuh tempo. Idempoten: aman dijalankan
# berulang kali karena satu penghuni hanya punya satu tagihan per periode.
class InvoiceGenerator
  LEAD_DAYS = 3

  def initialize(today: Date.current, tenants: Tenant.all)
    @today = today
    @tenants = tenants
  end

  # Mengembalikan tagihan yang baru dibuat.
  def call
    created = []

    @tenants.active.includes(room: :property).find_each do |tenant|
      candidate_months.each do |month|
        due_on = tenant.due_date_in(month)
        next unless due_on - LEAD_DAYS <= @today && tenant.billable_on?(due_on)

        invoice = create_invoice(tenant, month, due_on)
        created << invoice if invoice
      end
    end

    created
  end

  private
    # Bulan ini (termasuk susulan jika jadwal sempat terlewat) dan bulan
    # depan (jatuh tempo awal bulan yang masuk jendela H-3 di akhir bulan).
    def candidate_months
      [ @today.beginning_of_month, @today.next_month.beginning_of_month ]
    end

    def create_invoice(tenant, month, due_on)
      return if tenant.invoices.exists?(period: month)

      room = tenant.room
      tenant.invoices.create!(
        period: month,
        due_on: due_on,
        amount: room.monthly_rent,
        description: "Sewa #{room.property.name} kamar #{room.name} #{I18n.l(month, format: :month)}"
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end
end

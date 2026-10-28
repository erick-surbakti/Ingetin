# Biaya tambahan sekali bayar di tagihan bulan itu (listrik, air, laundry).
# Nominalnya sudah termasuk di Invoice#amount; tambah/hapus lewat
# Invoice#add_item! dan Invoice#remove_item! supaya total ikut berubah.
class InvoiceItem < ApplicationRecord
  MAX_AMOUNT = 10_000_000

  belongs_to :invoice

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 50 }
  validates :amount, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_AMOUNT }

  # Terima input seperti "75.000".
  def amount=(value)
    super(value.is_a?(String) ? value.gsub(/\D/, "").presence : value)
  end
end

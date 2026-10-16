# Satu percobaan bayar (satu transaksi Snap) untuk sebuah tagihan.
class Payment < ApplicationRecord
  CHANNELS = {
    "qris" => %w[ other_qris ],
    "va" => %w[ bca_va bni_va bri_va permata_va echannel cimb_va danamon_va bsi_va other_va ]
  }.freeze

  belongs_to :invoice

  validates :order_id, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :channel, inclusion: { in: CHANNELS.keys }
  validates :gross_amount, numericality: { only_integer: true, greater_than: 0 }
  validates :midtrans_transaction_id, uniqueness: true, allow_nil: true

  def self.generate_order_id(invoice)
    "ING-#{invoice.id}-#{SecureRandom.alphanumeric(8)}"
  end

  def owner
    invoice.tenant.room.property.user
  end

  def paid_via
    channel == "qris" ? "qris" : "bank_transfer"
  end
end

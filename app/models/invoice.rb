class Invoice < ApplicationRecord
  PAID_VIA = %w[ cash qris bank_transfer ].freeze
  PAID_VIA_LABELS = { "cash" => "Tunai", "qris" => "QRIS", "bank_transfer" => "Virtual Account" }.freeze

  class Locked < StandardError; end

  belongs_to :tenant
  has_many :payments, dependent: :restrict_with_error
  has_many :items, -> { order(:created_at, :id) }, class_name: "InvoiceItem", dependent: :destroy, inverse_of: :invoice

  has_secure_token :public_token, length: 24

  enum :status, { unpaid: "unpaid", paid: "paid" }, default: :unpaid, validate: true

  scope :for_period, ->(date) { where(period: date.beginning_of_month) }
  scope :overdue, ->(today = Date.current) { unpaid.where(due_on: ...today) }

  validates :period, :due_on, :description, presence: true
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :tenant_id, uniqueness: { scope: :period }
  validates :paid_via, inclusion: { in: PAID_VIA }, allow_nil: true

  def overdue?(today = Date.current)
    unpaid? && due_on < today
  end

  def number
    "INV-#{period.strftime("%Y%m")}-#{id.to_s.rjust(5, "0")}"
  end

  # Sewa pokok, tanpa biaya tambahan.
  def rent_amount
    amount - items.sum(&:amount)
  end

  # Menambah biaya tambahan; total tagihan ikut naik. Mengembalikan item
  # (cek item.persisted? / item.errors). Raise Locked jika tagihan tidak
  # boleh diubah lagi.
  def add_item!(name:, amount:)
    with_lock do
      ensure_items_editable!
      item = InvoiceItem.new(invoice: self, name: name, amount: amount)
      if item.save
        update!(amount: self.amount + item.amount)
        items.reset
        supersede_open_payments!
      end
      item
    end
  end

  def remove_item!(item)
    with_lock do
      ensure_items_editable!
      item.destroy!
      update!(amount: amount - item.amount)
      items.reset
      supersede_open_payments!
    end
  end

  # Alasan biaya tambahan tidak bisa diubah, atau nil jika boleh.
  def items_locked_reason
    if paid?
      "Tagihan sudah lunas."
    elsif payments.exists?(status: "pending")
      "Penghuni sedang menyelesaikan pembayaran Virtual Account dengan nominal lama."
    end
  end

  def mark_paid!(via:, at: Time.current)
    return false if paid?

    update!(status: :paid, paid_via: via, paid_at: at)
  end

  def mark_sent!
    update!(last_sent_at: Time.current, sent_count: sent_count + 1)
  end

  private
    def ensure_items_editable!
      reason = items_locked_reason
      raise Locked, reason if reason
    end

    # Transaksi Snap yang belum dipilih metodenya memakai nominal lama;
    # jangan dipakai ulang.
    def supersede_open_payments!
      payments.where(status: "created").update_all(status: "superseded", updated_at: Time.current)
    end
end

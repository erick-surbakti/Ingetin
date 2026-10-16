class Invoice < ApplicationRecord
  PAID_VIA = %w[ cash qris bank_transfer ].freeze

  belongs_to :tenant

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

  def mark_paid!(via:, at: Time.current)
    return false if paid?

    update!(status: :paid, paid_via: via, paid_at: at)
  end

  def mark_sent!
    update!(last_sent_at: Time.current, sent_count: sent_count + 1)
  end
end

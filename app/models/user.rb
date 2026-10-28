class User < ApplicationRecord
  PLANS = %w[ free pro ].freeze
  FREE_ROOM_LIMIT = 10

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :rooms, through: :properties
  has_many :tenants, through: :rooms
  has_many :invoices, through: :tenants
  has_many :payments, through: :invoices

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :plan, inclusion: { in: PLANS }
  validates :midtrans_server_key, format: { with: /\A(SB-)?Mid-server-[A-Za-z0-9_-]+\z/, message: "harus diawali Mid-server- atau SB-Mid-server-" },
    allow_blank: true
  validates :va_admin_fee, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }

  encrypts :midtrans_server_key

  normalizes :midtrans_server_key, with: ->(key) { key.strip.presence }

  # Terima input seperti "5.000".
  def va_admin_fee=(value)
    super(value.is_a?(String) ? value.gsub(/\D/, "").presence : value)
  end

  def midtrans_connected?
    midtrans_server_key.present?
  end

  # Server key sandbox diawali "SB-".
  def midtrans_sandbox_key?
    midtrans_server_key.to_s.start_with?("SB-")
  end

  # Key sandbox di aplikasi mode produksi (atau sebaliknya) selalu ditolak Midtrans.
  def midtrans_key_matches_environment?
    !midtrans_connected? || midtrans_sandbox_key? != Midtrans.production?
  end

  def midtrans_payment_received?
    payments.where.not(paid_at: nil).exists?
  end

  def masked_midtrans_server_key
    return if midtrans_server_key.blank?

    "#{midtrans_server_key.first(midtrans_server_key.start_with?("SB-") ? 14 : 11)}••••#{midtrans_server_key.last(4)}"
  end

  def free_plan?
    plan == "free"
  end

  def room_limit_reached?
    free_plan? && rooms.count >= FREE_ROOM_LIMIT
  end
end

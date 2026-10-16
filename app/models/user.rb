class User < ApplicationRecord
  PLANS = %w[ free pro ].freeze
  FREE_ROOM_LIMIT = 10

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :rooms, through: :properties
  has_many :tenants, through: :rooms

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :plan, inclusion: { in: PLANS }

  def free_plan?
    plan == "free"
  end

  def room_limit_reached?
    free_plan? && rooms.count >= FREE_ROOM_LIMIT
  end
end

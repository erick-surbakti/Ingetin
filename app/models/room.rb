class Room < ApplicationRecord
  belongs_to :property
  has_many :tenants, dependent: :restrict_with_error
  has_one :current_tenant, -> { active }, class_name: "Tenant"

  scope :vacant, -> { where.not(id: Tenant.active.select(:room_id)) }

  normalizes :name, with: ->(n) { n.squish }

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { scope: :property_id }
  validates :monthly_rent, numericality: { only_integer: true, greater_than: 0, less_than: 1_000_000_000 }
  validate :within_plan_limit, on: :create

  # Terima input seperti "1.500.000" atau "Rp 1.500.000".
  def monthly_rent=(value)
    super(value.is_a?(String) ? value.gsub(/\D/, "").presence : value)
  end

  def vacant?
    current_tenant.nil?
  end

  private
    def within_plan_limit
      owner = property&.user
      return unless owner&.room_limit_reached?

      errors.add(:base, "Paket Gratis maksimal #{User::FREE_ROOM_LIMIT} kamar. Upgrade ke Pro untuk menambah kamar.")
    end
end

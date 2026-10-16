class Tenant < ApplicationRecord
  PHONE_FORMAT = /\A628\d{7,11}\z/

  belongs_to :room, inverse_of: :tenants
  has_one :property, through: :room
  has_many :invoices, dependent: :restrict_with_error

  scope :active, -> { where(moved_out_on: nil) }
  scope :moved_out, -> { where.not(moved_out_on: nil) }

  normalizes :name, with: ->(n) { n.squish }
  normalizes :phone, with: ->(p) { PhoneNumber.normalize(p) }

  before_validation :default_due_day, on: :create

  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, format: { with: PHONE_FORMAT, message: "harus nomor HP Indonesia, contoh 0812xxxxxxxx" }
  validates :move_in_on, presence: true
  validates :due_day, numericality: { only_integer: true, in: 1..31 }
  validate :room_is_vacant
  validate :moved_out_not_before_move_in

  def active?
    moved_out_on.nil?
  end

  # Tagihan hanya untuk jatuh tempo setelah tanggal masuk (bulan pertama
  # dibayar saat masuk) dan tidak sebelum penghuni dicatat di aplikasi
  # (bulan yang sudah lewat dianggap sudah ditagih di luar aplikasi).
  def billable_on?(due_on)
    due_on > move_in_on && due_on >= created_at.to_date
  end

  # Tanggal jatuh tempo di bulan yang memuat `date`. Jatuh tempo 29–31
  # dipotong ke hari terakhir bulan yang lebih pendek.
  def due_date_in(date)
    month = date.beginning_of_month
    month.change(day: [ due_day, month.end_of_month.day ].min)
  end

  private
    def default_due_day
      self.due_day ||= move_in_on&.day
    end

    def room_is_vacant
      return unless active? && room

      if room.tenants.active.where.not(id: id).exists?
        errors.add(:room, "sudah ditempati penghuni lain")
      end
    end

    def moved_out_not_before_move_in
      return unless moved_out_on && move_in_on

      errors.add(:moved_out_on, "tidak boleh sebelum tanggal masuk") if moved_out_on < move_in_on
    end
end

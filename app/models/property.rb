class Property < ApplicationRecord
  belongs_to :user
  has_many :rooms, -> { order(:name) }, dependent: :restrict_with_error, inverse_of: :property

  normalizes :name, with: ->(n) { n.squish }
  normalizes :address, with: ->(a) { a.strip.presence }

  validates :name, presence: true, length: { maximum: 100 }
  validates :address, length: { maximum: 500 }
end

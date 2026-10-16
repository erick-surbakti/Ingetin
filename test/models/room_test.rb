require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "parses formatted rupiah input" do
    assert_equal 1_500_000, Room.new(monthly_rent: "Rp 1.500.000").monthly_rent
    assert_equal 750_000, Room.new(monthly_rent: 750_000).monthly_rent
  end

  test "rejects zero or blank rent" do
    room = properties(:melati).rooms.new(name: "Z1", monthly_rent: "0")
    assert_not room.valid?
    assert room.errors.of_kind?(:monthly_rent, :greater_than)

    room.monthly_rent = ""
    assert_not room.valid?
  end

  test "name is unique within a property" do
    duplicate = properties(:melati).rooms.new(name: "A1", monthly_rent: 1_000_000)
    assert_not duplicate.valid?

    other_property = properties(:mawar).rooms.new(name: "A1", monthly_rent: 1_000_000)
    assert other_property.valid?
  end

  test "vacant scope and predicate" do
    assert_not rooms(:melati_a1).vacant?
    assert rooms(:melati_a2).vacant?, "penghuni yang sudah keluar tidak menempati kamar"
    assert_equal %w[A2 A3], properties(:melati).rooms.vacant.pluck(:name)
  end

  test "free plan is limited to #{User::FREE_ROOM_LIMIT} rooms" do
    property = properties(:melati)
    (User::FREE_ROOM_LIMIT - property.user.rooms.count).times do |i|
      property.rooms.create!(name: "X#{i}", monthly_rent: 1_000_000)
    end

    room = property.rooms.new(name: "Lebih", monthly_rent: 1_000_000)
    assert_not room.valid?
    assert_match "maksimal #{User::FREE_ROOM_LIMIT} kamar", room.errors[:base].first

    property.user.update!(plan: "pro")
    assert room.valid?
  end
end

require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "normalizes phone and defaults due day to move-in day" do
    tenant = Tenant.create!(room: rooms(:melati_a2), name: " Sinta ", phone: "0812 9999 8888", move_in_on: Date.new(2026, 10, 17))

    assert_equal "Sinta", tenant.name
    assert_equal "6281299998888", tenant.phone
    assert_equal 17, tenant.due_day
  end

  test "rejects invalid phone numbers" do
    tenant = Tenant.new(room: rooms(:melati_a2), name: "X", phone: "12345", move_in_on: Date.current)
    assert_not tenant.valid?
    assert tenant.errors.of_kind?(:phone, :invalid)
  end

  test "an occupied room cannot take another active tenant" do
    tenant = Tenant.new(room: rooms(:melati_a1), name: "X", phone: "081200000000", move_in_on: Date.current)
    assert_not tenant.valid?
    assert_includes tenant.errors[:room], "sudah ditempati penghuni lain"
  end

  test "a room whose tenant moved out can be filled again" do
    tenant = Tenant.new(room: rooms(:melati_a2), name: "X", phone: "081200000000", move_in_on: Date.current)
    assert tenant.valid?
  end

  test "move-out date cannot precede move-in date" do
    tenant = tenants(:rina)
    tenant.moved_out_on = tenant.move_in_on - 1
    assert_not tenant.valid?
    assert tenant.errors.key?(:moved_out_on)
  end

  test "due date is clamped to the end of shorter months" do
    joko = tenants(:joko)
    assert_equal Date.new(2026, 2, 28), joko.due_date_in(Date.new(2026, 2, 5))
    assert_equal Date.new(2028, 2, 29), joko.due_date_in(Date.new(2028, 2, 1))
    assert_equal Date.new(2026, 4, 30), joko.due_date_in(Date.new(2026, 4, 30))
    assert_equal Date.new(2026, 5, 31), joko.due_date_in(Date.new(2026, 5, 1))
    assert_equal Date.new(2026, 11, 10), tenants(:rina).due_date_in(Date.new(2026, 11, 25))
  end
end

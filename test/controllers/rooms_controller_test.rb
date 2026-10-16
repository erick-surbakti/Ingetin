require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @property = properties(:melati)
  end

  test "create parses formatted rent" do
    assert_difference -> { @property.rooms.count }, 1 do
      post property_rooms_path(@property), params: { room: { name: "B1", monthly_rent: "1.750.000" } }
    end

    assert_redirected_to property_path(@property)
    assert_equal 1_750_000, @property.rooms.find_by!(name: "B1").monthly_rent
  end

  test "save and add another returns to the form" do
    post property_rooms_path(@property), params: { room: { name: "B2", monthly_rent: "1000000" }, add_another: "Simpan & tambah lagi" }
    assert_redirected_to new_property_room_path(@property)
  end

  test "create with invalid data" do
    post property_rooms_path(@property), params: { room: { name: "", monthly_rent: "" } }
    assert_response :unprocessable_content
  end

  test "update" do
    patch property_room_path(@property, rooms(:melati_a2)), params: { room: { monthly_rent: "1300000" } }
    assert_redirected_to property_path(@property)
    assert_equal 1_300_000, rooms(:melati_a2).reload.monthly_rent
  end

  test "cannot delete a room with tenant history" do
    assert_no_difference -> { Room.count } do
      delete property_room_path(@property, rooms(:melati_a2))
    end
    assert_redirected_to property_path(@property)
  end

  test "deletes a room that never had tenants" do
    assert_difference -> { Room.count }, -1 do
      delete property_room_path(@property, rooms(:melati_a3))
    end
  end

  test "another owner's rooms are not accessible" do
    other = properties(:mawar)

    post property_rooms_path(other), params: { room: { name: "Z", monthly_rent: "1" } }
    assert_response :not_found

    patch property_room_path(other, rooms(:mawar_b1)), params: { room: { monthly_rent: "1" } }
    assert_response :not_found

    # Kamar milik pemilik lain lewat properti sendiri juga tidak ditemukan.
    get edit_property_room_path(@property, rooms(:mawar_b1))
    assert_response :not_found
  end
end

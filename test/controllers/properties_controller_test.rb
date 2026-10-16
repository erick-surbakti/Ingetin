require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index lists only the owner's properties" do
    get properties_path
    assert_response :success
    assert_select "##{dom_id(properties(:melati))}"
    assert_select "##{dom_id(properties(:mawar))}", count: 0
  end

  test "create" do
    assert_difference -> { users(:one).properties.count }, 1 do
      post properties_path, params: { property: { name: "Kos Anggrek", address: "" } }
    end

    property = users(:one).properties.order(:created_at).last
    assert_redirected_to property_path(property)
    assert_nil property.address
  end

  test "create with invalid data" do
    post properties_path, params: { property: { name: " " } }
    assert_response :unprocessable_content
  end

  test "show and update" do
    get property_path(properties(:melati))
    assert_response :success
    assert_select "##{dom_id(rooms(:melati_a1))}", /Rina/

    patch property_path(properties(:melati)), params: { property: { name: "Kos Melati Indah" } }
    assert_redirected_to property_path(properties(:melati))
    assert_equal "Kos Melati Indah", properties(:melati).reload.name
  end

  test "cannot delete a property that still has rooms" do
    assert_no_difference -> { Property.count } do
      delete property_path(properties(:melati))
    end
    assert_redirected_to property_path(properties(:melati))
  end

  test "deletes an empty property" do
    property = users(:one).properties.create!(name: "Kosong")
    assert_difference -> { Property.count }, -1 do
      delete property_path(property)
    end
    assert_redirected_to properties_path
  end

  test "another owner's property is not accessible" do
    other = properties(:mawar)

    get property_path(other)
    assert_response :not_found

    patch property_path(other), params: { property: { name: "Diambil" } }
    assert_response :not_found
    assert_equal "Kos Mawar", other.reload.name

    delete property_path(other)
    assert_response :not_found
  end
end

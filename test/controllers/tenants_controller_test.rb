require "test_helper"

class TenantsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index shows active tenants, moved out tab shows history" do
    get tenants_path
    assert_response :success
    assert_select "##{dom_id(tenants(:rina))}"
    assert_select "##{dom_id(tenants(:dewi_moved_out))}", count: 0
    assert_select "##{dom_id(tenants(:joko))}", count: 0

    get tenants_path(status: "moved_out")
    assert_select "##{dom_id(tenants(:dewi_moved_out))}"
  end

  test "new offers only vacant rooms of the owner" do
    get new_tenant_path
    assert_response :success
    assert_select "option[value='#{rooms(:melati_a2).id}']"
    assert_select "option[value='#{rooms(:melati_a1).id}']", count: 0
    assert_select "option[value='#{rooms(:mawar_b1).id}']", count: 0
  end

  test "create" do
    assert_difference -> { Tenant.count }, 1 do
      post tenants_path, params: { tenant: {
        name: "Sinta", phone: "0812-9999-8888", room_id: rooms(:melati_a2).id,
        move_in_on: "2026-10-05", due_day: ""
      } }
    end

    assert_redirected_to tenants_path
    tenant = Tenant.find_by!(name: "Sinta")
    assert_equal "6281299998888", tenant.phone
    assert_equal 5, tenant.due_day
  end

  test "cannot place a tenant in another owner's room" do
    assert_no_difference -> { Tenant.count } do
      post tenants_path, params: { tenant: {
        name: "Penyusup", phone: "081200000000", room_id: rooms(:mawar_b1).id, move_in_on: "2026-10-01"
      } }
    end
    assert_response :unprocessable_content
  end

  test "update" do
    patch tenant_path(tenants(:rina)), params: { tenant: { phone: "0813 1111 2222", due_day: "15" } }
    assert_redirected_to tenants_path

    rina = tenants(:rina).reload
    assert_equal "6281311112222", rina.phone
    assert_equal 15, rina.due_day
  end

  test "move out keeps the tenant and frees the room" do
    patch move_out_tenant_path(tenants(:rina)), params: { tenant: { moved_out_on: "2026-10-31" } }
    assert_redirected_to tenants_path

    assert_equal Date.new(2026, 10, 31), tenants(:rina).reload.moved_out_on
    assert rooms(:melati_a1).reload.vacant?
  end

  test "another owner's tenant is not accessible" do
    get edit_tenant_path(tenants(:joko))
    assert_response :not_found

    patch move_out_tenant_path(tenants(:joko))
    assert_response :not_found
    assert tenants(:joko).reload.active?
  end
end

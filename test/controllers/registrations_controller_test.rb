require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "new redirects when already signed in" do
    sign_in_as users(:one)

    get new_registration_path
    assert_redirected_to root_path
  end

  test "create with valid data signs the owner in" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: { user: {
        name: "  Ibu   Rina ", email_address: " Rina@Example.com ",
        password: "rahasia123", password_confirmation: "rahasia123"
      } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?

    user = User.order(:created_at).last
    assert_equal "Ibu Rina", user.name
    assert_equal "rina@example.com", user.email_address
  end

  test "create with invalid data re-renders the form" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: {
        name: "", email_address: users(:one).email_address,
        password: "pendek", password_confirmation: "beda"
      } }
    end

    assert_response :unprocessable_content
    assert_select "#form_errors li", minimum: 3
  end
end

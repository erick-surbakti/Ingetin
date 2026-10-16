require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "squishes name" do
    assert_equal "Bu Sari", User.new(name: "  Bu   Sari ").name
  end

  test "requires name, valid unique email, and a password of at least 8 characters" do
    user = User.new(name: "", email_address: "bukan-email", password: "pendek")

    assert_not user.valid?
    assert user.errors.added?(:name, :blank)
    assert user.errors.added?(:email_address, :invalid, value: "bukan-email")
    assert user.errors.added?(:password, :too_short, count: 8)

    duplicate = User.new(name: "X", email_address: users(:one).email_address, password: "rahasia123")
    assert_not duplicate.valid?
    assert duplicate.errors.added?(:email_address, :taken, value: users(:one).email_address)
  end

  test "midtrans server key is validated, encrypted, and masked" do
    user = users(:one)

    user.midtrans_server_key = "bukan-key"
    assert_not user.valid?

    user.update!(midtrans_server_key: " SB-Mid-server-AbCdEf123456 ")
    assert_equal "SB-Mid-server-AbCdEf123456", user.reload.midtrans_server_key
    assert user.midtrans_connected?
    assert_equal "SB-Mid-server-••••3456", user.masked_midtrans_server_key

    raw = User.connection.select_value("SELECT midtrans_server_key FROM users WHERE id = #{user.id}")
    assert_not_includes raw, "AbCdEf123456"
  end

  test "va admin fee accepts formatted input within bounds" do
    user = users(:one)
    user.va_admin_fee = "4.000"
    assert_equal 4_000, user.va_admin_fee
    assert user.valid?

    user.va_admin_fee = "20000"
    assert_not user.valid?
  end
end

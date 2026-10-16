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
end

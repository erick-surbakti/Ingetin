require "test_helper"

class PhoneNumberTest < ActiveSupport::TestCase
  test "normalizes common Indonesian formats to 62 prefix" do
    assert_equal "6281234567890", PhoneNumber.normalize("0812-3456-7890")
    assert_equal "6281234567890", PhoneNumber.normalize("+62 812 3456 7890")
    assert_equal "6281234567890", PhoneNumber.normalize("6281234567890")
    assert_equal "6281234567890", PhoneNumber.normalize("81234567890")
    assert_equal "", PhoneNumber.normalize(nil)
  end

  test "displays in local format" do
    assert_equal "0812-3456-7890", PhoneNumber.display("6281234567890")
    assert_equal "", PhoneNumber.display(nil)
  end
end

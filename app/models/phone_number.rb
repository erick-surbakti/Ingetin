# Normalisasi nomor HP Indonesia ke format internasional tanpa "+"
# (628xxxxxxxxx), sesuai kebutuhan link wa.me.
module PhoneNumber
  module_function

  def normalize(raw)
    digits = raw.to_s.gsub(/\D/, "")

    if digits.start_with?("0")
      "62#{digits.delete_prefix("0")}"
    elsif digits.start_with?("8")
      "62#{digits}"
    else
      digits
    end
  end

  # 6281234567890 -> "0812-3456-7890"
  def display(number)
    return "" if number.blank?

    local = number.start_with?("62") ? "0#{number.delete_prefix("62")}" : number
    local.scan(/\d{1,4}/).join("-")
  end
end

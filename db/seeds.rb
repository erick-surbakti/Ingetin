# Data contoh untuk development. Aman dijalankan berulang kali.
# Login: demo@ingetin.test / password123

return if Rails.env.production?

owner = User.find_or_create_by!(email_address: "demo@ingetin.test") do |user|
  user.name = "Bu Demo"
  user.password = "password123"
end

property = owner.properties.find_or_create_by!(name: "Kos Melati") do |p|
  p.address = "Jl. Kenanga No. 5, Yogyakarta"
end

rooms = {
  "A1" => 1_500_000,
  "A2" => 1_250_000,
  "A3" => 1_250_000,
  "B1" => 1_000_000
}.map do |name, rent|
  property.rooms.find_or_create_by!(name: name) { |room| room.monthly_rent = rent }
end

[
  [ rooms[0], "Rina Lestari", "081234567890", Date.current.beginning_of_month - 3.months + 9.days ],
  [ rooms[1], "Andi Pratama", "085711112222", Date.current.beginning_of_month - 1.month + 27.days ]
].each do |room, name, phone, move_in_on|
  room.tenants.find_or_create_by!(name: name) do |tenant|
    tenant.phone = phone
    tenant.move_in_on = move_in_on
  end
end

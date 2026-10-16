# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_16_170000) do
  create_table "invoices", force: :cascade do |t|
    t.integer "tenant_id", null: false
    t.date "period", null: false
    t.date "due_on", null: false
    t.integer "amount", null: false
    t.string "description", null: false
    t.string "status", default: "unpaid", null: false
    t.datetime "paid_at"
    t.string "paid_via"
    t.string "public_token", null: false
    t.datetime "last_sent_at"
    t.integer "sent_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["public_token"], name: "index_invoices_on_public_token", unique: true
    t.index ["status", "due_on"], name: "index_invoices_on_status_and_due_on"
    t.index ["tenant_id", "period"], name: "index_invoices_on_tenant_id_and_period", unique: true
    t.index ["tenant_id"], name: "index_invoices_on_tenant_id"
    t.check_constraint "amount > 0", name: "invoices_amount_positive"
    t.check_constraint "status IN ('unpaid', 'paid')", name: "invoices_status_valid"
  end

  create_table "properties", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.integer "property_id", null: false
    t.string "name", null: false
    t.integer "monthly_rent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "name"], name: "index_rooms_on_property_id_and_name", unique: true
    t.index ["property_id"], name: "index_rooms_on_property_id"
    t.check_constraint "monthly_rent > 0", name: "rooms_monthly_rent_positive"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.integer "room_id", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.date "move_in_on", null: false
    t.integer "due_day", null: false
    t.date "moved_out_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_tenants_on_room_id"
    t.index ["room_id"], name: "index_tenants_on_room_id_active", unique: true, where: "moved_out_on IS NULL"
    t.check_constraint "due_day BETWEEN 1 AND 31", name: "tenants_due_day_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "plan", default: "free", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "invoices", "tenants"
  add_foreign_key "properties", "users"
  add_foreign_key "rooms", "properties"
  add_foreign_key "sessions", "users"
  add_foreign_key "tenants", "rooms"
end

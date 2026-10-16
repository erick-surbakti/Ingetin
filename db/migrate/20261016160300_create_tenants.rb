class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.references :room, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone, null: false
      t.date :move_in_on, null: false
      t.integer :due_day, null: false
      t.date :moved_out_on

      t.timestamps

      t.check_constraint "due_day BETWEEN 1 AND 31", name: "tenants_due_day_range"
    end
    # MVP: satu penghuni aktif per kamar.
    add_index :tenants, :room_id, unique: true, where: "moved_out_on IS NULL",
      name: "index_tenants_on_room_id_active"
  end
end

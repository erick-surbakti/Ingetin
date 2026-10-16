class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :monthly_rent, null: false

      t.timestamps

      t.check_constraint "monthly_rent > 0", name: "rooms_monthly_rent_positive"
    end
    add_index :rooms, %i[property_id name], unique: true
  end
end

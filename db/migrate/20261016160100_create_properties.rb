class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :address

      t.timestamps
    end
  end
end

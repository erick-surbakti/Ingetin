class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :order_id, null: false
      t.string :channel, null: false
      t.integer :gross_amount, null: false
      t.integer :admin_fee, null: false, default: 0
      t.string :status, null: false, default: "created"
      t.string :snap_token
      t.string :redirect_url
      t.string :midtrans_transaction_id
      t.string :payment_type
      t.datetime :paid_at
      t.datetime :expires_at, null: false
      t.text :last_notification

      t.timestamps

      t.check_constraint "channel IN ('qris', 'va')", name: "payments_channel_valid"
      t.check_constraint "gross_amount > 0", name: "payments_gross_amount_positive"
    end
    add_index :payments, :order_id, unique: true
    add_index :payments, :midtrans_transaction_id, unique: true
  end
end

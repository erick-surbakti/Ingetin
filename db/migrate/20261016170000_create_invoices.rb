class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :tenant, null: false, foreign_key: true
      t.date :period, null: false
      t.date :due_on, null: false
      t.integer :amount, null: false
      t.string :description, null: false
      t.string :status, null: false, default: "unpaid"
      t.datetime :paid_at
      t.string :paid_via
      t.string :public_token, null: false
      t.datetime :last_sent_at
      t.integer :sent_count, null: false, default: 0

      t.timestamps

      t.check_constraint "amount > 0", name: "invoices_amount_positive"
      t.check_constraint "status IN ('unpaid', 'paid')", name: "invoices_status_valid"
    end
    # Satu tagihan per penghuni per periode.
    add_index :invoices, %i[tenant_id period], unique: true
    add_index :invoices, :public_token, unique: true
    add_index :invoices, %i[status due_on]
  end
end

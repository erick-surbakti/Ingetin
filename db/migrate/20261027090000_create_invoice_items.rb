class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :amount, null: false

      t.timestamps

      t.check_constraint "amount > 0", name: "invoice_items_amount_positive"
    end
  end
end

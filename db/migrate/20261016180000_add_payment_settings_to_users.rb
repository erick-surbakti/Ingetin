class AddPaymentSettingsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :midtrans_server_key, :text
    add_column :users, :va_admin_fee, :integer, null: false, default: 5000
  end
end

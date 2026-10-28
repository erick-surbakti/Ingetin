class AddMidtransNotifiedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    # Terisi saat notifikasi Midtrans pertama (signature valid) diterima,
    # tanda URL notifikasi sudah dipasang dengan benar.
    add_column :users, :midtrans_notified_at, :datetime
  end
end

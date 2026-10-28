class PaymentSettingsController < ApplicationController
  def edit
    @user = Current.user
  end

  CHECK_MESSAGES = {
    valid: [ :notice, "Server key valid. Ingetin bisa terhubung ke akun Midtrans-mu." ],
    unauthorized: [ :alert, "Server key ditolak Midtrans. Pastikan yang disalin adalah Server Key (bukan Client Key) dari mode yang benar." ],
    unreachable: [ :alert, "Midtrans tidak bisa dihubungi. Coba lagi beberapa saat lagi." ],
    not_configured: [ :alert, "Isi server key Midtrans dulu, lalu cek koneksi." ]
  }.freeze

  def check
    type, message = CHECK_MESSAGES.fetch(MidtransConnectionCheck.new(Current.user).call)
    redirect_to edit_payment_settings_path(anchor: "panduan"), type => message
  end

  def update
    @user = Current.user
    attributes = params.expect(user: %i[ midtrans_server_key va_admin_fee ])
    # Kosong berarti tidak mengganti server key yang sudah tersimpan.
    attributes.delete(:midtrans_server_key) if attributes[:midtrans_server_key].blank?

    if @user.update(attributes)
      redirect_to edit_payment_settings_path, notice: "Pengaturan pembayaran disimpan."
    else
      render :edit, status: :unprocessable_content
    end
  end
end

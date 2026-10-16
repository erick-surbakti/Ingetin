class PaymentSettingsController < ApplicationController
  def edit
    @user = Current.user
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

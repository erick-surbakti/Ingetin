class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_registration_path, alert: "Terlalu banyak percobaan. Coba lagi beberapa menit lagi." }

  def new
    return redirect_to root_path if authenticated?

    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Akun berhasil dibuat. Selamat datang di Ingetin!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def user_params
      params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
    end
end

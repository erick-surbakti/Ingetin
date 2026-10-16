class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Atur ulang kata sandi Ingetin", to: user.email_address
  end
end

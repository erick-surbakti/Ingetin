# Mengecek server key pemilik kos dengan menanyakan status order yang
# pasti tidak ada. Key yang valid menghasilkan "order tidak ditemukan"
# (404); key yang salah ditolak dengan HTTP 401.
class MidtransConnectionCheck
  def initialize(user)
    @user = user
  end

  # :valid, :unauthorized, :unreachable, atau :not_configured
  def call
    return :not_configured unless @user.midtrans_connected?

    Midtrans.client_for(@user).transaction_status("ING-CEK-#{SecureRandom.alphanumeric(10)}")
    :valid
  rescue Midtrans::Unauthorized
    :unauthorized
  rescue Midtrans::Error
    :unreachable
  end
end

class PublicInvoicesController < ApplicationController
  allow_unauthenticated_access

  def show
    @invoice = Invoice.includes(tenant: { room: { property: :user } }).find_by!(public_token: params[:token])
    response.set_header("X-Robots-Tag", "noindex, nofollow")
  end
end

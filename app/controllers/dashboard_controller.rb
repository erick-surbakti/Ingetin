class DashboardController < ApplicationController
  def show
    @property_count = Current.user.properties.count
    @month = Date.current.beginning_of_month
    invoices = Current.user.invoices.for_period(@month).includes(tenant: { room: :property })
    @summary = InvoiceSummary.new(invoices)
  end
end

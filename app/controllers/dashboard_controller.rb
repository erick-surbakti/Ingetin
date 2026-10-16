class DashboardController < ApplicationController
  def show
    @property_count = Current.user.properties.count
    @room_count = Current.user.rooms.count
    @active_tenant_count = Current.user.tenants.active.count
  end
end

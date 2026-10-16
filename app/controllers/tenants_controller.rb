class TenantsController < ApplicationController
  before_action :set_tenant, only: %i[ edit update move_out ]

  def index
    @status = params[:status] == "moved_out" ? "moved_out" : "active"
    scope = Current.user.tenants.includes(room: :property)
    @tenants = (@status == "active" ? scope.active : scope.moved_out).order(:name)
  end

  def new
    @tenant = Tenant.new(move_in_on: Date.current, room: owned_room(params[:room_id]))
    load_room_options
  end

  def create
    @tenant = Tenant.new(tenant_params.except(:room_id))
    @tenant.room = owned_room(tenant_params[:room_id])

    if @tenant.save
      redirect_to tenants_path, notice: "#{@tenant.name} ditambahkan ke kamar #{@tenant.room.name}."
    else
      load_room_options
      render :new, status: :unprocessable_content
    end
  end

  def edit
    load_room_options
  end

  def update
    attributes = tenant_params
    @tenant.assign_attributes(attributes.except(:room_id))
    @tenant.room = owned_room(attributes[:room_id]) if attributes.key?(:room_id)

    if @tenant.save
      redirect_to tenants_path, notice: "Data #{@tenant.name} diperbarui."
    else
      load_room_options
      render :edit, status: :unprocessable_content
    end
  end

  def move_out
    moved_out_on = params.dig(:tenant, :moved_out_on).presence || Date.current

    if @tenant.update(moved_out_on: moved_out_on)
      redirect_to tenants_path, notice: "#{@tenant.name} ditandai keluar. Riwayatnya tetap tersimpan."
    else
      redirect_to edit_tenant_path(@tenant), alert: @tenant.errors.full_messages.to_sentence
    end
  end

  private
    def set_tenant
      @tenant = Current.user.tenants.find(params[:id])
    end

    def tenant_params
      params.expect(tenant: %i[ name phone room_id move_in_on due_day ])
    end

    # Hanya kamar milik pemilik yang sedang login; selain itu nil
    # sehingga validasi "Kamar harus diisi" yang muncul.
    def owned_room(id)
      Current.user.rooms.find_by(id: id) if id.present?
    end

    def load_room_options
      properties = Current.user.properties.includes(rooms: :current_tenant).order(:name)

      @room_options = properties.filter_map do |property|
        rooms = property.rooms.select { |room| room.vacant? || room.id == @tenant.room_id }
        next if rooms.empty?

        [ property.name, rooms.map { |room| [ "#{room.name} · #{helpers.number_to_currency(room.monthly_rent)}", room.id ] } ]
      end
    end
end

class RoomsController < ApplicationController
  before_action :set_property
  before_action :set_room, only: %i[ edit update destroy ]

  def new
    @room = @property.rooms.new
  end

  def create
    @room = @property.rooms.new(room_params)

    if @room.save
      if params[:add_another].present?
        redirect_to new_property_room_path(@property), notice: "Kamar #{@room.name} ditambahkan."
      else
        redirect_to @property, notice: "Kamar #{@room.name} ditambahkan."
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @room.update(room_params)
      redirect_to @property, notice: "Kamar #{@room.name} diperbarui."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @room.destroy
      redirect_to @property, notice: "Kamar #{@room.name} dihapus.", status: :see_other
    else
      redirect_to @property, alert: @room.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_property
      @property = Current.user.properties.find(params[:property_id])
    end

    def set_room
      @room = @property.rooms.find(params[:id])
    end

    def room_params
      params.expect(room: %i[ name monthly_rent ])
    end
end

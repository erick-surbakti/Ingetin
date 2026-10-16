class PropertiesController < ApplicationController
  before_action :set_property, only: %i[ show edit update destroy ]

  def index
    @properties = Current.user.properties.includes(rooms: :current_tenant).order(:name)
  end

  def show
    @rooms = @property.rooms.includes(:current_tenant)
  end

  def new
    @property = Current.user.properties.new
  end

  def create
    @property = Current.user.properties.new(property_params)

    if @property.save
      redirect_to @property, notice: "Properti ditambahkan. Sekarang tambahkan kamar."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: "Properti diperbarui."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @property.destroy
      redirect_to properties_path, notice: "Properti dihapus.", status: :see_other
    else
      redirect_to @property, alert: @property.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_property
      @property = Current.user.properties.find(params[:id])
    end

    def property_params
      params.expect(property: %i[ name address ])
    end
end

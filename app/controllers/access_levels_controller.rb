class AccessLevelsController < ApplicationController
  before_action :set_access_level, only: %i[ show update destroy ]

  # GET /access_levels
  def index
    @access_levels = AccessLevel.all

    render json: @access_levels
  end

  # GET /access_levels/1
  def show
    render json: @access_level
  end

  # POST /access_levels
  def create
    @access_level = AccessLevel.new(access_level_params)

    if @access_level.save
      render json: @access_level, status: :created, location: @access_level
    else
      render json: @access_level.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /access_levels/1
  def update
    if @access_level.update(access_level_params)
      render json: @access_level
    else
      render json: @access_level.errors, status: :unprocessable_entity
    end
  end

  # DELETE /access_levels/1
  def destroy
    @access_level.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_access_level
      @access_level = AccessLevel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def access_level_params
      params.fetch(:access_level, {})
    end
end

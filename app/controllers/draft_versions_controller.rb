class DraftVersionsController < ApplicationController
  before_action :set_draft_version, only: %i[ show update destroy ]

  # GET /draft_versions
  def index
    @draft_versions = DraftVersion.all

    render json: @draft_versions
  end

  # GET /draft_versions/1
  def show
    render json: @draft_version
  end

  # POST /draft_versions
  def create
    @draft_version = DraftVersion.new(draft_version_params)

    if @draft_version.save
      render json: @draft_version, status: :created, location: @draft_version
    else
      render json: @draft_version.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /draft_versions/1
  def update
    if @draft_version.update(draft_version_params)
      render json: @draft_version
    else
      render json: @draft_version.errors, status: :unprocessable_entity
    end
  end

  # DELETE /draft_versions/1
  def destroy
    @draft_version.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_draft_version
      @draft_version = DraftVersion.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def draft_version_params
      params.fetch(:draft_version, {})
    end
end

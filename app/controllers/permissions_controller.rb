class PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_permission, only: [ :show ]

  def index
    permissions = Permission.ransack(params[:q]).result

    if params[:order_by].present?
      order_params = params[:order_by].split(",")
      permissions = permissions.order(order_params)
    else
      permissions = permissions.order(created_at: :desc)
    end

    if params[:per_page].to_i == -1
      permissions = permissions.all
      return render json: {
        data: permissions.as_json,
        current_page: 1,
        per_page: permissions.size,
        total_pages: 1,
        total: permissions.size,
        first_page: true,
        last_page: true,
        out_of_range: false
      }
    else
      permissions = permissions.page(params[:page] || 1).per(params[:per_page] || 10)
    end

    render json: {
      data: permissions.as_json,
      current_page: permissions.current_page,
      per_page: permissions.limit_value,
      total_pages: permissions.total_pages,
      total: permissions.total_count,
      first_page: permissions.first_page?,
      last_page: permissions.last_page?,
      out_of_range: permissions.out_of_range?
    }
  end

  def show
    render json: @permission.as_json, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Permission not found with id #{params[:id]}" }, status: :not_found
  end


  private

  def set_permission
    @permission = Permission.find(params[:id])
  end

  def permission_params
    params.require(:permission).permit(:name, :description)
  end
end

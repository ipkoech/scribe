class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: [ :show, :update, :destroy, :add_permissions, :remove_permissions, :add_users, :remove_users ]

  # Add the Rswag::Api documentation
  def index
     authorize User
      roles = Role.ransack(params[:q]).result

      if params[:order_by].present?
        order_params = params[:order_by].split(",")
        roles = roles.order(order_params)
      else
        roles = roles.order(created_at: :desc)
      end

      if params[:per_page].to_i == -1
        roles = roles.all
        return render json: {
          data: roles.as_json(include:  [ :permissions, :users ]),
          current_page: 1,
          per_page: roles.size,
          total_pages: 1,
          total: roles.size,
          first_page: true,
          last_page: true,
          out_of_range: false
        }
      else
        roles = roles.page(params[:page] || 1).per(params[:per_page] || 10)
      end

      render json: {
        data: roles.as_json(include: [ :permissions, :users ]),
        current_page: roles.current_page,
        per_page: roles.limit_value,
        total_pages: roles.total_pages,
        total: roles.total_count,
        first_page: roles.first_page?,
        last_page: roles.last_page?,
        out_of_range: roles.out_of_range?
      }
  end

  def show
    authorize User
    role = Role.find(params[:id])
    render json: role.as_json(include:  [ :permissions, :users ]), status: :ok
  end

  def create
    authorize User
    role = Role.new(role_params.except(:permission_ids))

    if role.save
      attach_permissions(role, params[:permission_ids])
      render json: role.as_json, status: :created
    else
      render json: { errors: role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def detach_permissions
    authorize @role, :detach_permissions?

    permissions = Permission.where(id: params[:permission_ids])

    if @role.permissions.delete(permissions)
      render json: @role.as_json(include: :permissions), status: :ok
    else
      render json: { errors: @role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # New method to add permissions to a role
  def add_permissions
    authorize @role
    permission_ids = params[:permission_ids] || []
    attach_permissions(@role, permission_ids)
    render json: @role.as_json(include: [ :permissions ]), status: :ok
  end

  # New method to remove permissions from a role
  def remove_permissions
    authorize @role
    permissions = Permission.where(id: params[:permission_ids])
    if @role.permissions.destroy(permissions)
      render json: @role.as_json(include: [ :permissions ]), status: :ok
    else
      render json: { errors: @role.errors.full_messages }, status: :unprocessable_entity
    end
  end

    # Method to add users to a role
    def add_users
      authorize @role, :add_users?
      user_ids = params[:user_ids] || []
      users = User.where(id: user_ids)

      if users.any?
        @role.users << users
        render json: @role.as_json(include: [ :users ]), status: :ok
      else
        render json: { errors: [ "No valid users found" ] }, status: :unprocessable_entity
      end
    end

    # Optional: Method to remove users from a role
    def remove_users
      authorize @role, :remove_users?
      user_ids = params[:user_ids] || []
      users = User.where(id: user_ids)

      if users.any?
        @role.users.destroy(users)
        render json: @role.as_json(include: [ :users ]), status: :ok
      else
        render json: { errors: [ "No valid users found" ] }, status: :unprocessable_entity
      end
    end



  def update
    authorize @role
    if @role.update(role_params)
      render json: @role.as_json, status: :ok
    else
      render json: { errors: @role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @role
    @role.destroy
    render json: { message: "Role deleted successfully" }, status: :ok
  end

  private
  def attach_permissions(role, permission_ids)
    permission_ids.each do |permission_id|
      permission = Permission.find(permission_id)
      role.permissions << permission
    end
  end

  def set_role
    @role = Role.find(params[:id])
  end
  def role_params
    params.require(:role).permit(:name, :description, permission_ids: [], user_ids: [])
  end
end

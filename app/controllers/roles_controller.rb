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

  def add_permissions
    authorize @role
    permission_ids = params[:permission_ids] || []
    attach_permissions(@role, permission_ids)
    render json: @role.as_json(include: [:permissions]), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue => e
    Rails.logger.error("Error adding permissions to role #{role.id}: #{e.message}")
    render json: { error: "An unexpected error occurred while adding permissions." }, status: :internal_server_error
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
    # Fetch existing permission IDs associated with the role
    existing_permission_ids = role.permissions.pluck(:id)

    # Determine which permission IDs are new
    new_permission_ids = permission_ids - existing_permission_ids

    # Attach only new permissions
    role.permissions << Permission.where(id: new_permission_ids)

    # Optionally, handle cases where some permission IDs are invalid or not found
    invalid_permission_ids = permission_ids - Permission.where(id: permission_ids).pluck(:id)
    unless invalid_permission_ids.empty?
      raise ActiveRecord::RecordInvalid.new(role), "Some permissions do not exist: #{invalid_permission_ids.join(', ')}"
    end
  end

  def set_role
    @role = Role.find(params[:id])
  end
  def role_params
    params.require(:role).permit(:name, :description, permission_ids: [], user_ids: [])
  end
end

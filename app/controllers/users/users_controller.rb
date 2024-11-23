class Users::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :destroy, :show, :update ]
  before_action :authorize_user, only: [ :destroy, :show, :update ]

  wrap_parameters :user, include: [ :email, :password ]
  def assign_roles
    authorize User, :assign_roles?

    user = User.find(params[:user_id])
    return render json: { error: "User not found with id #{params[:user_id]}" }, status: :not_found if user.nil?

    roles = Role.where(id: params[:role_ids])
    return render json: { error: "No roles found with provided IDs" }, status: :not_found if roles.empty?

    user.roles << roles
    if user.save
      # NotificationService.notify(
      #   user: user,
      #   trigger_name: "role_assigned",
      #   title: "Role Assigned",
      #   body: "The role '#{roles.map(&:name).join(', ')}' has been assigned."
      # )
      render json: user.as_json(include: :roles), status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def detach_roles
    authorize User, :detach_roles?

    user = User.find_by(id: params[:user_id])
    return render json: { error: "User not found" }, status: :not_found if user.nil?

    roles = Role.where(id: params[:role_ids])
    return render json: { error: "No roles found with provided IDs" }, status: :not_found if roles.empty?

    user.roles.delete(roles)
    if user.save
      # NotificationService.notify(
      #   user: user,
      #   trigger_name: "role_revoked",
      #   title: "Role Revoked",
      #   body: "The role '#{roles.map(&:name).join(', ')}' has been revoked."
      # )
      render json: { message: "Roles detached successfully", user: user.as_json(include: :roles) }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Uploading the profile picture
  def update_profile_image
    blob_service = AzureService.new
    uploaded_file = params[:profile_image]

    if uploaded_file.present?
      begin
        # Ensure the file is properly processed before upload
        uploaded_file.tempfile.binmode
        azure_url = blob_service.upload(uploaded_file, current_user.id, "profile_image")

        @media = current_user.media.create!(
          title: "profile_image_#{Time.current.to_i}",
          azure_url: azure_url,
          content_type: uploaded_file.content_type,
          size: uploaded_file.size
        )

        current_user.update!(profile_image: azure_url)

        render json: {
          media: @media,
          profile_image_url: azure_url
        }, status: :ok
      rescue => e
        Rails.logger.error("Upload error: #{e.message}")
        render json: { error: e.message }, status: :unprocessable_entity
      end
    else
      render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end
  end

  def create
    authorize User
    created_users = []
    errors = []

    ActiveRecord::Base.transaction do
      begin
        params.require(:users).each do |user_params|
          random_password = SecureRandom.hex(8)

          merged_params = user_params.permit(:name, :email, role_ids: [])
                                     .merge(password: random_password, password_confirmation: random_password)

          user = User.new(merged_params.except(:role_ids))  # Exclude role_ids from initial assignment
          if user.save
            assign_roles_to_user(user, user_params[:role_ids]) if user_params[:role_ids].present?  # Assign roles after user creation
            created_users << user
            UserMailer.invitation_email(user, random_password).deliver_later
          else
            errors << { user: user_params, errors: user.errors.full_messages }
            raise ActiveRecord::Rollback
          end
        end
      rescue ActionController::ParameterMissing => e
        errors << { error: "Missing parameters: #{e.message}" }
        raise ActiveRecord::Rollback
      rescue ActiveRecord::RecordInvalid => e
        errors << { error: "Failed to create user: #{e.message}" }
        raise ActiveRecord::Rollback
      end
    end

    if errors.empty?
      render json: created_users.as_json, status: :created
    else
      render json: errors.as_json, status: :unprocessable_entity
    end
  end


  def destroy
    authorize User
    @user = User.find(params[:id])
    return render json: { error: "Admin users cannot be deleted" }, status: :forbidden if @user.admin?
    # Rails.logger.info current_user.name
    ActiveRecord::Base.transaction do
      begin
        @user.destroy!
        render json: { message: "User deleted successfully" }, status: :ok
      rescue ActiveRecord::ActiveRecordError => e
        render json: { error: "Failed to delete user: #{e.message}" }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def index
    authorize User
    users = User.ransack(params[:q]).result
    users = users.order(params[:order_by].split(",")) if params[:order_by].present?

    if params[:per_page].to_i == -1
      users = users.all
      render json: format_users_response(users), status: :ok
    else
      users = users.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: format_users_response(users), status: :ok
    end
  end

  def show
    render json: @user.as_json(except: [ :encrypted_password, :reset_password_token, :confirmation_token, :unlock_token ], methods: [ :roles, :drafts ]), status: :ok
  end

  def update
    authorize User
    @user = User.find(params[:id])
    original_attributes = @user.attributes.slice("name", "email", "otp_enabled", "otp_secret_key")
    original_role_ids = @user.role_ids

    if @user.update(user_params.except(:role_ids))
      assign_roles_to_user(@user, params[:role_ids]) if params[:role_ids].present?

      changes = detect_changes(original_attributes, @user.attributes.slice("name", "email", "otp_enabled", "otp_secret_key"))
      role_changes = detect_role_changes(original_role_ids, @user.role_ids)
      changes.merge!(role_changes)

      # NotificationService.notify(
      #   user: @user,
      #   trigger_name: "user_updated",
      #   title: "User Details Updated",
      #   body: "The details of user '#{@user.name}' have been updated: #{format_changes(changes)}"
      # )

      render json: { message: "User updated successfully", changes: changes }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def current
    render json: current_user.as_json(except: [ :encrypted_password, :reset_password_token, :confirmation_token, :unlock_token ], methods: [ :roles ]), status: :ok
  end

  def chat
    @user = User.find(params[:id])

    user_input = params[:user_input]

    chat_service = ChatService.new(user_input, @user.id)
    @chat_response = chat_service.call

    if @chat_response
      chat_response_html = markdown_to_html(@chat_response)

      render json: chat_response_html, status: :ok
    else
      render json: { error: "Chat API request failed" }, status: :unprocessable_entity
    end
  end

  def permissions
    authorize User, :permissions?
    permissions = Permission.all
    render json: permissions.as_json, status: :ok
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    authorize @user
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :otp_enabled, :otp_secret_key, role_ids: [])
  end

  def assign_roles_to_user(user, role_ids)
    roles = Role.where(id: role_ids)
    user.roles = roles if roles.present?
  end

  def detect_changes(original, updated)
    changes = {}
    original.each do |key, value|
      changes[key.to_sym] = { from: value, to: updated[key] } if value != updated[key]
    end
    changes
  end

  def detect_role_changes(original_role_ids, updated_role_ids)
    changes = {}
    added_roles = Role.where(id: updated_role_ids - original_role_ids).pluck(:name)
    removed_roles = Role.where(id: original_role_ids - updated_role_ids).pluck(:name)

    changes[:roles_added] = added_roles unless added_roles.empty?
    changes[:roles_removed] = removed_roles unless removed_roles.empty?
    changes
  end

  def format_changes(changes)
    changes.map do |key, value|
      if key == :roles_added
        "Roles added: #{value.join(', ')}"
      elsif key == :roles_removed
        "Roles removed: #{value.join(', ')}"
      else
        "#{key.to_s.humanize} changed from #{value[:from]} to #{value[:to]}"
      end
    end.join(", ")
  end

  def markdown_to_html(markdown_text)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    markdown.render(markdown_text)
  end

  def format_users_response(users)
    {
      data: users.as_json(include: :roles),
      current_page: 1,
      per_page: users.size,
      total_pages: 1,
      total: users.count,
      first_page: true,
      last_page: true,
      out_of_range: false
    }
  end
end

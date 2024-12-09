class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[ show destroy ]
  before_action :authenticate_user!

  def index
    @q = current_user.received_notifications.ransack(params[:q])
    notifications = @q.result(distinct: true)

    # Apply default ordering if no sort parameter is provided
    notifications = notifications.order(created_at: :desc) unless params.dig(:q, :s)

    # Apply pagination
    notifications = notifications.page(params[:page] || 1).per(params[:per_page] || 10)

    render json: {
      data: notifications.as_json(
        only: [:id, :action, :data, :read_at, :created_at, :updated_at],
        include: {
          actor: { only: [:id, :name, :email] },
          notifiable: { only: [:id, :type] },
        },
      ),
      current_page: notifications.current_page,
      per_page: notifications.size,
      total_pages: notifications.total_pages,
      total: notifications.total_count,
      first_page: notifications.first_page?,
      last_page: notifications.last_page?,
      out_of_range: notifications.out_of_range?,
    }
  rescue => e
    render json: { error: "Failed to load notifications.", details: e.message }, status: :internal_server_error
  end

  def create
    @notification = Notification.new(notification_params)
    if @notification.save
      render json: @notification, status: :created
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    notification = Notification.find(params[:id])
    authorize notification
    render json: notification.as_json, status: :ok
  end

  def destroy
    notification = Notification.find(params[:id])
    authorize notification
    notification.destroy
    render json: nil, status: :no_content
  end

  def mark_all_as_read
    notifications = current_user.notifications.where(id: params[:ids], read_at: nil)
    notification_ids = notifications.pluck(:id)
    notifications.update_all(read_at: Time.now)    # Broadcast a single event with all marked-as-read notification IDs
    NotificationChannel.broadcast_to(
      "notification_channel.#{current_user.id}",
      notification_ids: notification_ids,
      action: "bulk_read",
    )

    render json: { success: true }, status: :ok
  end

  def mark_as_read
    notification = Notification.find(params[:id])
    authorize notification, :mark_as_read?
    notification.mark_as_read if notification.read_at.nil?
    render json: notification.as_json, status: :ok
  end

  def mark_all_as_read
    notifications = Notification.where(recipient: current_user).unread
    notifications.mark_all_as_read!(current_user)

    render json: { success: true, message: "All notifications marked as read." }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_notification
    @notification = Notification.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def notification_params
    params.fetch(:notification, {})
  end
end

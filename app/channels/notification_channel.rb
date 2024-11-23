class NotificationChannel < ApplicationCable::Channel
  include Pundit::Authorization

  def subscribed
    @user = find_verified_user
    authorize_and_stream
  rescue StandardError => e
    reject
  end

  def unsubscribed
    stop_all_streams
  end

  def receive(data)
    process_notification_update(data)
  rescue StandardError => e
    broadcast_error(e.message)
  end

  private

  def find_verified_user
    User.find_by!(id: params[:user_id])
  end

  def authorize_and_stream
    if policy(@user).show?
      stream_for @user
      broadcast_connection_status("connected")
    else
      raise Pundit::NotAuthorizedError
    end
  end

  def process_notification_update(data)
    notification_ids = data["notification_ids"]
    return broadcast_error("Missing notification IDs") unless notification_ids.present?

    ActiveRecord::Base.transaction do
      notifications = current_user.notifications.where(id: notification_ids, read_at: nil)
      updated_count = notifications.update_all(read_at: Time.current)
      broadcast_update_result(notification_ids, updated_count)
    end
  end

  def broadcast_update_result(notification_ids, count)
    NotificationChannel.broadcast_to(
      current_user,
      {
        notification_ids: notification_ids,
        action: "bulk_read",
        updated_at: Time.current,
        updated_count: count,
        status: "success",
      }
    )
  end

  def broadcast_error(message)
    NotificationChannel.broadcast_to(
      current_user,
      {
        action: "error",
        message: message,
        timestamp: Time.current,
      }
    )
  end

  def broadcast_connection_status(status)
    NotificationChannel.broadcast_to(
      current_user,
      {
        action: "connection_status",
        status: status,
        timestamp: Time.current,
      }
    )
  end

  def policy(record)
    NotificationPolicy.new(current_user, record)
  end
end

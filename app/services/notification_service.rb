# app/services/notification_service.rb
class NotificationService
  class NotificationError < StandardError; end

  def self.notify(user:, body:, extra_params: {})
    new(user, body, extra_params).deliver
  end

  def initialize(user, body, extra_params = {})
    @user = user
    @body = body
    @extra_params = extra_params
    @title = extra_params[:title]
  end

  def deliver
    ActiveRecord::Base.transaction do
      create_notification
      broadcast_notification
    end

    enqueue_email_job
    true
  rescue StandardError => e
    Rails.logger.error("Notification delivery failed: #{e.message}")
    raise NotificationError, "Failed to deliver notification: #{e.message}"
  end

  private

  attr_reader :user, :body, :extra_params, :title, :notification

  def create_notification
    @notification = Notification.create!(
      recipient: user,
      actor: extra_params[:actor],
      notifiable_type: extra_params[:notifiable_type],
      notifiable_id: extra_params[:notifiable_id],
      action: "create",
      data: extra_params.merge(title: title),
    )
  end

  def broadcast_notification
    NotificationChannel.broadcast_to(
      user,
      {
        action: "create",
        notification: notification.as_json(include: [:recipient, :actor]),
      }
    )
  end

  def enqueue_email_job
    SendNotificationEmailJob.perform_later(
      user_id: user.id,
      title: title,
      body: body,
      extra_params: extra_params,
    )
  end
end

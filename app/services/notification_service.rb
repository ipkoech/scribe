class NotificationService
  class NotificationError < StandardError; end

  def self.notify(user:, title:, body:, extra_params: {})
    new(user, title, body, extra_params).deliver
  end

  def initialize(user, title, body, extra_params = {})
    @user = user
    @title = title
    @body = body
    @extra_params = extra_params
  end

  def deliver
    ActiveRecord::Base.transaction do
      create_notification
      # send_email
      broadcast_notification
      # track_delivery
    end
    true
  rescue StandardError => e
    Rails.logger.error("Notification delivery failed: #{e.message}")
    raise NotificationError, "Failed to deliver notification: #{e.message}"
  end

  private

  attr_reader :user, :title, :body, :extra_params

  def create_notification
    @notification = Notification.create!(
      user: user,
      title: title,
      body: body,
      metadata: extra_params,
      status: "pending",
    )
  end

  def send_email
    UserMailer.custom_notification_email(
      user,
      title,
      body,
      extra_params
    ).deliver_later
  end

  def broadcast_notification
    NotificationChannel.broadcast_to(
      user,
      {
        action: "create",
        notification: @notification.as_json(include: :user),
      }
    )
  end

  def track_delivery
    @notification.update!(
      delivered_at: Time.current,
      status: "delivered",
    )
  end
end

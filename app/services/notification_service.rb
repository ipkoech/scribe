class NotificationService
  class NotificationError < StandardError; end

  def self.notify(user:, body:, extra_params: {})
    new(user, body, extra_params).deliver
  end

  def initialize(user, body, extra_params = {})
    @user = user
    @body = body
    @extra_params = extra_params
    @title = extra_params[:title]  # Extract title from extra_params
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

  attr_reader :user, :body, :extra_params, :title

  def create_notification
    @notification = Notification.create!(
      recipient: user,  # Correctly assign recipient_id
      actor: @extra_params[:actor], # Assuming actor_id is passed in extra_params
      notifiable_type: @extra_params[:notifiable_type], # e.g., "Draft"
      notifiable_id: @extra_params[:notifiable_id], # e.g., draft.id
      action: @extra_params[:action] || "added_collaborator", # Default action
      data: @extra_params.merge({ title: title }), # Include title in data
    )
  end

  def send_email
    UserMailer.custom_notification_email(
      user,
      title,  # Pass title for email
      body,
      extra_params
    ).deliver_later
  end

  def broadcast_notification
    NotificationChannel.broadcast_to(
      user,
      {
        action: "create",
        notification: @notification.as_json(include:  [:recipient, :actor]),
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

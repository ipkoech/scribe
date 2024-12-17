# app/jobs/send_notification_email_job.rb
class SendNotificationEmailJob < ApplicationJob
  queue_as :default

  # Retry on all StandardError exceptions, with a wait time of 5 seconds, up to 3 attempts.
  retry_on StandardError, wait: 5.seconds, attempts: 3

  # If the user record is missing, we won't retry as it's likely a permanent error.
  rescue_from ActiveRecord::RecordNotFound do |error|
    Rails.logger.error("User not found for notification email: #{error.message}")
    # Possibly send alert or notify a monitoring service here.
  end

  def perform(user_id:, title:, body:, extra_params:)
    user = User.find(user_id)

    UserMailer.custom_notification_email(
      user,
      title,
      body,
      extra_params
    ).deliver_now
  end
end

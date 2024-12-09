class UserMailer < ApplicationMailer
  default from: "accounts@egric.com"

  def otp_sent(user)
    @user = user
    @otp_code = user.otp_code
    mail(to: @user.email, subject: "Your OTP Code")
  end

  def invitation_email(user, random_password)
    @url = "http://localhost:4200/login"
    @user = user
    @random_password = random_password
    mail(to: @user.email, subject: "Invitation and Password Information")
  end

  def reset_password_instructions(user, token)
    @user = user
    @token = token
    mail(to: @user.email, subject: "Reset password instructions")
  end

  def password_change(user)
    @user = user
    mail(to: @user.email, subject: "Password Changed Successfully")
  end

  def email_changed(user, email)
    @user = user
    @mail = email
    mail(to: @user.email, subject: "Email Changed Successfully")
  end


  # Role Assigned Notification
  def role_assigned(user, roles)
    custom_notification_email(user, "Roles Assigned", "You have been assigned the following roles: #{roles.join(', ')}", "role_assigned", { roles: roles })
  end

  # Role Revoked Notification
  def role_revoked(user, roles)
    custom_notification_email(user, "Roles Revoked", "The following roles have been revoked: #{roles.join(', ')}", "role_revoked", { roles: roles })
  end

  # User Details Updated Notification
  def user_updated(user, changes)
    custom_notification_email(user, "User Details Updated", "Your details have been updated: #{changes.inspect}", "user_updated", { changes: changes })
  end

  # Task Created Notification
  def task_created(user, task)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks/#{task.id}"
    custom_notification_email(user, "A new task '#{task.title}' has been created", "Task details: #{task.description}", "task_created", { task: task, frontend_url: frontend_url })
  end

  # Task Updated Notification
  def task_updated(user, task)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks/#{task.id}"
    custom_notification_email(user, "'#{task.title}' has been updated", "Updated task details: #{task.description}", "task_updated", { task: task, frontend_url: frontend_url })
  end

  # Task Deleted Notification
  def task_deleted(user, task_title, description, status)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks"
    custom_notification_email(user, "Task '#{task_title}' Deleted", "Task details: #{description}, Status: #{status}", "task_deleted", { task_title: task_title, frontend_url: frontend_url })
  end

  # Task Assigned Notification
  def task_assigned(user, task)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks/#{task.id}"
    custom_notification_email(user, "'#{task.title}' Assigned", "You have been assigned to the task: #{task.title}", "task_assigned", { task: task, frontend_url: frontend_url })
  end

  # Task Completed Notification
  def task_completed(user, task)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks/#{task.id}"
    custom_notification_email(user, "'#{task.title}' Completed", "The task '#{task.title}' has been completed.", "task_completed", { task: task, frontend_url: frontend_url })
  end

  # Task Cancelled Notification
  def task_cancelled(user, task)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks/#{task.id}"
    custom_notification_email(user, "'#{task.title}' Cancelled", "The task '#{task.title}' has been cancelled.", "task_cancelled", { task: task, frontend_url: frontend_url })
  end

  # Task Due Soon Notification
  def task_due(user, task)
    frontend_url = "#{Rails.application.credentials.frontend_url}/tasks/#{task.id}"
    custom_notification_email(user, "'#{task.title}' Due Soon", "The task '#{task.title}' is due soon.", "task_due", { task: task, frontend_url: frontend_url })
  end


def custom_notification_email(user, title, body, extra_params = {})
  @user = user
  @title = title
  @body = body

  # Extract trigger_name from extra_params
  trigger_name = extra_params.delete(:trigger_name)

  # Safely handle model lookups
  extra_params.each do |key, value|
    if key.to_s.end_with?("_id") && value.present?
      model_name = key.to_s.chomp("_id").classify
      begin
        instance_variable_set("@#{model_name.underscore}", model_name.constantize.find(value))
      rescue NameError => e
        Rails.logger.warn("Could not find model: #{model_name}")
      end
    else
      instance_variable_set("@#{key}", value)
    end
  end

  mail(to: @user.email, subject: @title) do |format|
    format.html { render "user_mailer/#{trigger_name}" }
  end
end


end

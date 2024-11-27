class UserChannel < ApplicationCable::Channel
  include Pundit::Authorization

  def subscribed
    @user = User.find_by(id: params[:user_id])
    if @user && policy(@user).show?
      stream_for @user
    else
      Rails.logger.error("Pundit::NotAuthorizedError:")
      reject
    end
  rescue Pundit::NotAuthorizedError
    reject
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def policy(record)
    Pundit.policy!(current_user, record)
  end
end

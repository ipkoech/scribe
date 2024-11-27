class DraftChannel < ApplicationCable::Channel
  include Pundit::Authorization

  def subscribed
    @draft = Draft.find_by(id: params[:draft_id])
    if @draft && policy(@draft).show?
      stream_for @draft
    else
      Rails.logger.error("Pundit::NotAuthorizedError: User not authorized to access draft")
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

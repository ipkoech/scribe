class CommentChannel < ApplicationCable::Channel
  include Pundit::Authorization

  def subscribed
    @comment = Comment.find_by(id: params[:comment_id])
    if @comment && policy(@comment).show?
      stream_for @comment
    else
      Rails.logger.error("Comment not found or unavailable for comments streaming")
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def policy(record)
    Pundit.policy!(current_user, record)
  end
end

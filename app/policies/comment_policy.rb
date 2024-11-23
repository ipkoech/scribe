class CommentPolicy < ApplicationPolicy
  attr_reader :user, :comment

  def initialize(user, comment)
    @user = user
    @comment = comment
  end

  def show?
    @commentable = comment.commentable_type.constantize.find(comment.commentable_id)
    authorize @commentable, :show_comment?
  end

  def create?
    true
  end

  def update?
    @commentable = comment.commentable_type.constantize.find(comment.commentable_id)
    authorize @commentable, :update_comment? || user_is_owner?
  end

  def destroy?
    @commentable = comment.commentable_type.constantize.find(comment.commentable_id)
    authorize @commentable, :destroy_comment? || user_is_owner?
  end

  private

  def user_is_owner?
    comment.user == user
  end

  def user_has_permission?(permission)
    user.has_permission?(permission)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user_owned_comments = scope.where(user_id: user.id)
      comments_on_collaborations = scope.where(
        commentable_id: user.collaborations.select(:id),
        commentable_type: user.collaborations.name,
      )
      user_owned_comments.or(comments_on_collaborations)
    end
  end
end

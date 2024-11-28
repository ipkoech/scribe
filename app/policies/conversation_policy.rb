class ConversationPolicy < ApplicationPolicy
  attr_reader :user, :conversation

  def initialize(user, record)
    @user = user
    @conversation = record
  end

  def index?
    true  # Any authenticated user can view their own conversations
  end

  def show?
    user_is_owner? || user_is_shared_user? || user_is_super_admin?
  end

  def create?
    user.present?  # Any authenticated user can create a conversation
  end

  def update?
    user_is_owner? || user_is_super_admin?
  end

  def archive?
    user_is_owner? || user_is_super_admin?
  end

  def share?
    user_is_owner? || user_is_super_admin?
  end

  def destroy?
    user_is_owner? || user_is_super_admin?
  end

  private

  def user_is_owner?
    conversation.user == user
  end

  def user_is_shared_user?
    conversation.shared_users.include?(user)
  end

  def user_is_super_admin?
    user.roles.exists?(name: "Super Admin")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.roles.exists?(name: "Super Admin")
        scope.all
      else
        scope.joins(:shared_users).where("conversations.user_id = ? OR conversations_users.user_id = ?", user.id, user.id)
      end
    end
  end
end

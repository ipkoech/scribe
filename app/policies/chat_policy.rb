class ChatPolicy < ApplicationPolicy
  attr_reader :user, :chat, :conversation

  def initialize(user, record)
    @user = user
    @chat = record
    @conversation = chat.conversation
  end

  def create?
    user_is_conversation_member? || user_is_super_admin?
  end

  def index?
    user_is_conversation_member? || user_is_super_admin?
  end

  def update?
    (user_is_conversation_member? && user_is_owner_of_chat?) || user_is_super_admin?
  end

  def highlight?
    (user_is_conversation_member? && user_is_owner_of_chat?) || user_is_super_admin?
  end

  def like?
    user_is_conversation_member? || user_is_super_admin?
  end

  def dislike?
    user_is_conversation_member? || user_is_super_admin?
  end

  private

  def user_is_conversation_member?
    conversation.users.include?(user)
  end

  def user_is_owner_of_chat?
    chat.user == user
  end

  def user_is_super_admin?
    user.roles.exists?(name: "Super Admin")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.roles.exists?(name: "Super Admin")
        scope.all
      else
        scope.joins(:conversation).where(conversations: { user_id: user.id })
      end
    end
  end
end

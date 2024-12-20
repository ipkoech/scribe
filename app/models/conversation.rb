class Conversation < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  # A conversation can be shared with multiple users
  has_and_belongs_to_many :shared_users, class_name: "User", join_table: "conversations_users"

  # validates :title, allow_nil: true

  scope :active, -> { where(archived: false) }

  after_create_commit :broadcast_create

  private

  def broadcast_create
    ActionCable.server.broadcast(
      "conversation_channel_#{self.id}",
      {
        action: "create",
        chat: self.as_json,
      }
    )
  end

  # Broadcasts a message to the conversation's channel
  def broadcast_message(message)
    ActionCable.server.broadcast(
      "conversation_channel_#{self.id}",
      {
        action: "message",
        chat: message.as_json,
      }
    )
  end

  # Broadcasts on update
  def broadcast_update
    ActionCable.server.broadcast(
      "conversation_channel_#{self.id}",
      {
        action: "update",
        chat: self.as_json,
      }
    )
  end
end

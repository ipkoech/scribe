class Chat < ApplicationRecord
  belongs_to :conversation
  has_one_attached :file
  enum :role, { user: "user", bot: "bot" }

  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy
  # Scope liked
  scope :liked, -> { where(liked: true) }
  # Scope disliked
  scope :disliked, -> { where(disliked: true) }
  # Utility methods for like/dislike
  def like!
    update(liked: true, disliked: false)
  end

  def dislike!
    update(liked: false, disliked: true)
  end

  def remove_feedback!
    update(liked: false, disliked: false)
  end

  private

  def broadcast_create
    ActionCable.server.broadcast(
      "chat_channel_#{conversation_id}",
      {
        action: "create",
        chat: self.as_json,
      }
    )
  end

  def broadcast_update
    ActionCable.server.broadcast(
      "chat_channel_#{conversation_id}",
      {
        action: "update",
        chat: self.as_json,
      }
    )
  end

  def broadcast_destroy
    ActionCable.server.broadcast(
      "chat_channel_#{conversation_id}",
      {
        action: "destroy",
        chat_id: id,
      }
    )
  end
end

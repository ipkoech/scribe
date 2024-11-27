class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(5) }

  after_create_commit :broadcast_creation
  after_update_commit :broadcast_update

  def mark_as_read!
    update(read_at: Time.current)
  end

  private

  def broadcast_creation
    NotificationChannel.broadcast_to(
      recipient,
      {
        action: "create",
        notification: self.as_json(include: [:actor, :notifiable]),
      }
    )
  end

  def broadcast_update
    NotificationChannel.broadcast_to(
      recipient,
      {
        action: "update",
        notification: self.as_json(include: [:actor, :notifiable]),
      }
    )
  end
end

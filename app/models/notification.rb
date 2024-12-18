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

  # Batch mark as read and broadcast
  def self.mark_all_as_read!(user)
    where(recipient: user, read_at: nil).update_all(read_at: Time.current)

    # Broadcast a bulk read event to the user's notification channel
    NotificationChannel.broadcast_to(
      user,
      {
        action: "bulk_read",
        notification_ids: where(recipient: user).pluck(:id), # IDs of notifications just marked as read
      }
    )
  end

  # Ransack Configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[
      action
      actor_id
      created_at
      data
      id
      notifiable_id
      notifiable_type
      read_at
      recipient_id
      updated_at
    ]
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

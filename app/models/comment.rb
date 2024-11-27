class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true, optional: false

  validates :content, presence: true, length: { minimum: 1 }
  validates :user, presence: true
  validates :commentable_type, presence: true
  validates :commentable_id, presence: true

  validate :commentable_exists
  validate :valid_commentable_type

  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy
  scope :recent, -> { order(created_at: :desc) }

  def as_json(options = {})
    super(options).merge(
      commentable_type: commentable_type,
      commentable: commentable.as_json,
    )
  end

  private

  # Ensure the commentable object exists
  def commentable_exists
    return if commentable_type.constantize.exists?(commentable_id)

    errors.add(:commentable, "must be a valid #{commentable_type}")
  rescue NameError
    errors.add(:commentable_type, "is not a valid class")
  end

  def valid_commentable_type
    allowed_types = ["Draft"]
    unless allowed_types.include?(commentable_type)
      errors.add(:commentable_type, "must be one of the following: #{allowed_types.join(", ")}")
    end
  end

  def broadcast_create
    DraftChannel.broadcast_to(commentable, { action: "create", comment: as_json(include: :user) })
  end

  def broadcast_update
    CommentChannel.broadcast_to(self, { action: "update", comment: as_json(include: :user) })
  end

  def broadcast_destroy
    CommentChannel.broadcast_to(self, { action: "destroy", comment_id: id })
  end
end

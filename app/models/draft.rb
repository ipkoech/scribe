class Draft < ApplicationRecord
  belongs_to :author, class_name: "User", foreign_key: "user_id"

  has_many :draft_versions, dependent: :destroy

  # Collaborator associations
  has_many :drafts_users, dependent: :destroy
  has_many :collaborators, through: :drafts_users, source: :user, class_name: "User"

  has_many :comments, as: :commentable, dependent: :destroy
  has_many_attached :files

  after_update_commit :broadcast_update

  validates :title, presence: true
  validates :content, presence: true
  validates :status, presence: true

  scope :active, -> { where(active: true) }
  scope :status, ->(status) { where(status: status) }

  def as_json(options = {})
    super(options).merge(
      files: files.map { |file| file_details(file) },
    )
  end

  def broadcast_update
    CollaborationChannel.broadcast_to(
      self,
      draft: self.as_json(include: [:author, :collaborators]),
      action: "update",
    )
  end

  private

  def file_details(file)
    {
      filename: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size,
      url: Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true),
    }
  end
end

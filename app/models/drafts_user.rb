class DraftsUser < ApplicationRecord
  belongs_to :draft
  belongs_to :user

  validates :access_level, presence: true
  validates :draft_id, uniqueness: { scope: :user_id }

  scope :by_access_level, ->(level) { where(access_level: level) }
end

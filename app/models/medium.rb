class Medium < ApplicationRecord
  has_one_attached :file
  belongs_to :user

  validates :title, presence: true
  validates :azure_url, presence: true

  before_save :set_metadata

  private

  def set_metadata
    if file.attached?
      self.size = file.byte_size
      self.azure_url = file.url
      self.content_type = file.content_type
    end
  end
end

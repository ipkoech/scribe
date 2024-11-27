class Permission < ApplicationRecord
  has_and_belongs_to_many :roles
  belongs_to :access_level
  belongs_to :category

  validates :name, presence: true, uniqueness: true
  validates :scope, presence: true

  scope :active, -> { where(is_active: true) }
  scope :for_resource, ->(resource_type) { where(resource_type: resource_type) }

  def self.grouped_by_category
    all.group_by(&:category)
  end

  def activate
    update(is_active: true)
  end

  def deactivate
    update(is_active: false)
  end
end

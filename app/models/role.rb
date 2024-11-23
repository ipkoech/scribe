class Role < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :permissions

  validates :name, presence: true, uniqueness: true
  validates :hierarchy_level, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
  scope :system_roles, -> { where(is_system_role: true) }

  def assign_permission(permission)
    permissions << permission unless permissions.include?(permission)
  end

  def remove_permission(permission)
    permissions.delete(permission)
  end

  def active_permissions
    permissions.where(is_active: true)
  end
end

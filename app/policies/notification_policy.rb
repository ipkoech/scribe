class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.user == user
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.user == user
  end

  def destroy?
    user.present? && record.user == user
  end

  def mark_as_read?
    user.present? && record.user == user
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end

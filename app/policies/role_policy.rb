class RolePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end
  def detach_permissions?
    user.admin? || user.has_role?(:admin)
  end
  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def add_users?
    user.admin? || user.has_permission?("manage_roles")
  end

  def remove_users?
    user.admin? || user.has_permission?("manage_roles")
  end

  def add_permissions?
    user.admin?
  end

  def remove_permissions?
    user.admin?
  end


  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

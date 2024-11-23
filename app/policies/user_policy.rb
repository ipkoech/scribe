class UserPolicy < ApplicationPolicy
  def index?
    return true if user.roles.exists?(name: "Super Admin")
    has_permission?("index")
  end

  def show?
    return true if user.roles.exists?(name: "Super Admin")
    has_permission?("show") || record.id == user.id
  end

  def create?
    return true if user.roles.exists?(name: "Super Admin")
    has_permission?("create")
  end

  def update?
    return true if user.roles.exists?(name: "Super Admin")
    has_permission?("update") || record.id == user.id
  end

  def destroy?
    return true if user.roles.exists?(name: "Super Admin")
    has_permission?("destroy")
  end

  def change_role?
    return true if user.roles.exists?(name: "Super Admin")
    has_permission?("change_role")
  end

  class Scope < Scope
    def resolve
      if user.roles.exists?(name: "Super Admin")
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end

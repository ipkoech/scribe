class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    has_permission?("index")
  end

  def show?
    has_permission?("show")
  end

  def create?
    has_permission?("create")
  end

  def update?
    has_permission?("update")
  end

  def destroy?
    has_permission?("destroy")
  end

  private

  def has_permission?(action)
    return false unless user
    return true if user.roles.exists?(name: "SuperAdmin")

    user_roles = user.roles.where(is_active: true)
    Permission.joins(:roles)
              .where(roles: { id: user_roles.pluck(:id) })
              .exists?(
                action: action,
                resource_type: record.class.name,
                is_active: true
              )
  end


  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.roles.joins(:permissions)
             .where(permissions: { action: "index", resource_type: scope.name })
             .exists?
        scope.all
      else
        scope.none
      end
    end

    private

    attr_reader :user, :scope
  end
end

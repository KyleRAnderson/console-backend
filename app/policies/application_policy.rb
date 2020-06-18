class ApplicationPolicy
  attr_reader :user, :record, :permission

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      # This should never get raised if authentication is done properly
      raise Pundit::NotAuthorizedError, 'must be logged in' unless user

      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  def initialize(user, record)
    # This should never get raised if authentication is done properly
    raise Pundit::NotAuthorizedError, 'must be logged in' unless user

    @user = user
    @record = record
    @permission = record.permissions.find_by(user_id: user.id)
    raise Pundit::NotAuthorizedError, 'must have permission record' unless permission
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def create?
    permission.owner? || permission.administrator? || permission.operator?
  end

  def update?
    permission.owner? || permission.administrator? || permission.operator?
  end

  def destroy?
    permission.owner? || permission.administrator? || permission.operator?
  end
end

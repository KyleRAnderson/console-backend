class ConsolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:permissions).where(permissions: { user: user })
    end
  end

  def initialize(*args)
    super(*args)
    @permission = record.permissions.find_by(user: user)
  end

  def create?
    permission.is_at_least?(:operator)
  end

  def update?
    create?
  end

  def destroy?
    permission.is_at_least?(:operator)
  end

  protected

  attr_reader :permission
end

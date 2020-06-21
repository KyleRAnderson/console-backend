class ConsolePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:permissions).where(permissions: { user: user })
    end
  end

  def index?
    permission.present?
  end

  def show?
    permission.present?
  end

  def create?
    # Use case: something like roster.hunts.build(name: 'whatever')
    # will still have .permissions available without being saved
    # so this should still work.s
    permission&.at_least?(:operator)
  end

  def update?
    create?
  end

  def destroy?
    permission&.at_least?(:operator)
  end

  protected

  def permission
    @permission ||= record.permissions.find_by(user: user)
  end
end

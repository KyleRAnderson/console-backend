class PermissionPolicy < ApplicationPolicy
  alias_method :permission, :record

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def initialize(*args)
    super(*args)
    @user_roster_permission = user.permissions.find_by(roster: permission.roster)
  end

  def show?
    # Permission is one of their own or user is an owner or admin on the permission's roster.
    owns_permission? || owner_or_admin?
  end

  def create?
    owner_or_admin?
  end

  def update?
    # Must authorize the permission after the attributes have been changed
    # but not saved. Need to know what things are changing to in order to authorize
    # the changes
    if permision.level_changed?(to: 'owner')
      user_roster_permission.owner?
    else
      # Nobody can demote an owner, instead an owner is demoted by promoting
      # another user to owner.
      !permission.level_changed?(from: 'owner') && owner_or_admin?
    end
  end

  def destroy?
    owns_permission? || owner_or_admin?
  end

  private

  attr_reader :user_roster_permission

  def owner_or_admin?
    user_roster_permission&.is_at_least(:administrator)
  end

  def owns_permission?
    # True if the current user owns the current permission, false otherwise
    user.permissions.exists?(permission&.id)
  end
end

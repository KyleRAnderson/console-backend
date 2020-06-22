class PermissionPolicy < ApplicationPolicy
  alias_method :permission, :record

  class Scope < Scope
    def resolve
      scope.where(user: user)
        .or(scope.where(roster: user.rosters.joins(:permissions)
                          .where(permissions: { level: %i[owner administrator operator] })))
        .distinct
    end
  end

  def initialize(*args)
    super(*args)
    @user_roster_permission = user.permissions.find_by(roster: permission.roster)
  end

  def show?
    # Permission is one of their own or user is an owner or admin on the permission's roster.
    owns_permission? || user_roster_permission.at_least?(:operator)
  end

  def create?
    # Will need built object to know if user has permission to create.
    user_roster_permission.owner? ||
      (user_roster_permission.administrator? &&
       !permission.owner?)
  end

  def update?
    # Must authorize the permission after the attributes have been changed
    # but not saved. Need to know what things are changing to in order to authorize
    # the changes
    user_roster_permission.owner? ||
      (user_roster_permission.administrator? &&
       !permission.level_changed?(from: 'owner') &&
       !permission.level_changed?(from: 'administrator') &&
       !permission.level_changed?(to: 'owner'))
  end

  def destroy?
    owns_permission? ||
      user_roster_permission.owner? ||
      (user_roster_permission.administrator? &&
       !permission.at_least?(:administrator))
  end

  private

  attr_reader :user_roster_permission

  def owns_permission?
    # True if the current user owns the current permission, false otherwise
    user.permissions.exists?(permission&.id)
  end
end

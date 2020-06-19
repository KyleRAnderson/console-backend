class RosterPolicy < ConsolePolicy
  # Uses default console policy scope class.

  def index?
    permission.is_at_least?(:administrator)
  end

  def destroy?
    permission.owner?
  end
end

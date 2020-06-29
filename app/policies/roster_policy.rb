class RosterPolicy < ConsolePolicy
  # Uses default console policy scope class.

  def create?
    true
  end

  def update?
    permission&.at_least?(:administrator)
  end

  def destroy?
    permission&.owner?
  end
end

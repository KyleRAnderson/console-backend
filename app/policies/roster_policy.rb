class RosterPolicy < ConsolePolicy
  # Uses default console policy scope class.

  def initialize(*args)
    # Not requiring permission means we'll have to check it all the time now.
    super(*args, require_permission: false)
  end

  def index?
    permission&.is_at_least?(:administrator)
  end

  def create?
    true
  end

  def update?
    permission&.is_at_least?(:administrator)
  end

  def destroy?
    permission&.owner?
  end
end

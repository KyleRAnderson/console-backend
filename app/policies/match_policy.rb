class MatchPolicy < ConsolePolicy
  def matchmake?
    create?
  end

  protected

  def permission
    # Little bit of custom logic, since things are a little deeper with matches.
    @permission ||= record.round&.hunt&.roster&.permissions.find_by(user: user)
  end
end

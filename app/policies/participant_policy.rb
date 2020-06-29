class ParticipantPolicy < ConsolePolicy
  def upload?
    create?
  end
end

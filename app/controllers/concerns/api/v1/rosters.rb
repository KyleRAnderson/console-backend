module Api::V1::Rosters
  def current_roster
    @current_roster ||= Roster.find_by(id: params[:roster_id])
    authorized = RosterPolicy.new(current_user, @current_roster).show?
    head :not_found and return unless authorized

    @current_roster
  end
end

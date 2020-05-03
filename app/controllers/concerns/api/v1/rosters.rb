module Api::V1::Rosters
  def current_roster
    roster = Roster.find(params[:roster_id])
    return roster if roster.user == current_user
  end
end

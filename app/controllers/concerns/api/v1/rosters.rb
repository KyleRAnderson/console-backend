module Api::V1::Rosters
  def current_roster
    @current_roster ||= current_user&.rosters&.find_by(id: params[:roster_id])
    head :not_found and return unless @current_roster

    @current_roster
  end
end

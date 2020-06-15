module Api::V1::Hunts
  def current_hunt
    unless @hunt
      @hunt ||= Hunt.joins(roster: :permissions)
                    .find_by(id: params[:hunt_id], rosters: { permissions: { user_id: current_user.id } })
    end
    head :not_found and return unless @hunt

    @hunt
  end
end

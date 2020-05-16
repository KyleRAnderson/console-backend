module Api::V1::Hunts
  def current_hunt
    unless @hunt
      hunt = Hunt.find_by(id: params[:hunt_id])
      @hunt ||= hunt.roster.user == current_user ? hunt : nil
    end
    head :not_found and return unless @hunt

    @hunt
  end
end

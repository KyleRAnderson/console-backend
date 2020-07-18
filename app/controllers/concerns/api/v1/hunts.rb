module Api::V1::Hunts
  def current_hunt
    @hunt ||= Hunt.find_by(id: params[:hunt_id])
    authorized = HuntPolicy.new(current_user, @hunt).show?
    head :not_found and return unless authorized

    @hunt
  end
end

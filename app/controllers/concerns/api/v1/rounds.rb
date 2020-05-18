module Api::V1::Rounds
  def current_round
    @current_round ||= current_hunt&.rounds&.find_by(number: params[:round_number])
    head :not_found and return unless @current_round

    @current_round
  end
end

class Api::V1::Matches::EditsController < ApplicationController
  include Api::V1::Hunts

  wrap_parameters :edit_info, include: %i[pairings]

  before_action :authenticate_user!
  before_action :current_hunt

  def create
    current_round = current_hunt.current_round || current_hunt.rounds.create
    authorize current_round.matches.build
    MatchEditorJob.perform_later current_round, params.dig(:edit_info, :pairings)
    head :ok
  rescue MatchEditArgumentError => e
    render json: e.errors, status: :unprocessable_entity
  end
end

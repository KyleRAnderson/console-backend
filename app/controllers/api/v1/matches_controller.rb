class Api::V1::MatchesController < ApplicationController
  include Api::V1::Rounds

  before_action :authenticate_user!
  before_action :current_round
  before_action :prepare_match, except: %i[index create]

  def index
    render json: current_round.matches, status: :ok
  end

  def show
    render json: @match, status: :ok
  end

  def create
    match = current_round.matches.build(match_params)
    save_and_render_resource(match)
  end

  def destroy
    destroy_and_render_resource(@match)
  end

  private

  def match_params
    params.require(:match).permit(:participants, :open)
  end

  def prepare_match
    @match ||= current_round.matches.find_by(local_id: params[:number])
    head :not_found unless @match
  end
end

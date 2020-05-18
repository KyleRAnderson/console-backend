class Api::V1::RoundsController < ApplicationController
  include Api::V1::Hunts

  before_action :authenticate_user!
  before_action :current_hunt
  before_action :prepare_round, except: %i[index create]

  def index
    render json: current_hunt.rounds, status: :ok
  end

  def create
    round = current_hunt.rounds.build(round_params)
    save_and_render_resource(round)
  end

  def show
    render json: @round, status: :ok
  end

  def destroy
    destroy_and_render_resource(@round)
  end

  private

  def round_params
    params.require(:round).permit(:number)
  end

  def prepare_round
    @round ||= current_hunt.rounds.find_by(number: params[:number])
    head :not_found unless @round
  end
end

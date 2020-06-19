class Api::V1::MatchesController < ApplicationController
  include Api::V1::Hunts
  include Api::V1::PaginationOrdering

  before_action :authenticate_user!
  before_action :current_hunt
  before_action :prepare_match, except: %i[index create matchmake]

  def index
    render json: paginated(current_hunt
             .matches.includes(:licenses, :participants), key: :matches), status: :ok
  end

  def show
    render json: @match, status: :ok
  end

  def create
    match = current_hunt.matches.build(match_params)
    save_and_render_resource(match)
  end

  def matchmake
    MatchmakeLicensesJob.perform_later(current_hunt, matchmake_params.to_h)
    head :ok
  end

  private

  def match_params
    params.require(:match).permit(:license_ids, :open)
  end

  def prepare_match
    @match ||= current_hunt.matches.find_by(local_id: params[:number])
    head :not_found unless @match
  end

  def matchmake_params
    params.require(:matchmake).permit(within: [], between: [])
  end
end

class Api::V1::MatchesController < ApplicationController
  include Api::V1::Hunts
  include Api::V1::PaginationOrdering

  AS_JSON_OPTIONS = { include: { licenses: { only: %i[id eliminated], methods: :match_numbers,
                                           include: { participant: { only: %i[id first last extras] } } } } }.freeze

  before_action :authenticate_user!
  before_action :current_hunt
  before_action :current_round, only: %i[create]
  # Prepare match before authorizing it.
  before_action :prepare_match, except: %i[index create matchmake]
  before_action :authorize_match, except: %i[index create matchmake]

  def index
    matches = policy_scope(apply_filters(current_hunt.matches))
    render json: paginated(matches.includes(:licenses, :participants), key: :matches).as_json(**AS_JSON_OPTIONS), status: :ok
  end

  def show
    render json: @match.as_json(**AS_JSON_OPTIONS), status: :ok
  end

  def create
    match = current_round.matches.build(match_params)
    save_and_render_resource(authorize(match), json_opts: AS_JSON_OPTIONS)
  end

  def matchmake
    # Since the round and new match are just being used as storage objects for getting to
    # the roster, it's fine to create a new one here if one doesn't exist.
    correct_round = current_round || Round.new(hunt: current_hunt)
    authorize Match.new(round: correct_round)
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

  def authorize_match
    authorize @match
  end

  def matchmake_params
    params.require(:matchmake).permit(within: [], between: [])
  end

  def apply_filters(matches)
    matches = matches.joins(:round).where(rounds: { number: params[:round] }) if params[:round].present?
    matches = params[:ongoing] == 'true' ? matches.ongoing : matches.closed if params[:ongoing].present?
    matches
  end

  def current_round
    @current_round ||= current_hunt.current_round
    head :not_found unless @current_round
    @current_round
  end
end

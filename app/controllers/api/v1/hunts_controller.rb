class Api::V1::HuntsController < ApplicationController
  include Api::V1::Rosters

  before_action :authenticate_user!
  # This will make sure that the current roster is set,
  # if not render 404 before action is called.
  before_action :current_roster, only: %i[index create]
  # Prepare hunt before authorizing it.
  before_action :prepare_hunt, except: %i[index create]
  before_action :authorize_hunt, except: %i[index create update]

  AS_JSON_OPTIONS = { methods: %i[num_active_licenses current_round_number attachment_urls] }.freeze

  def index
    render json: policy_scope(current_roster.hunts).includes(:licenses).as_json(**AS_JSON_OPTIONS), status: :ok
  end

  def show
    render json: @hunt
             .as_json(**AS_JSON_OPTIONS.merge({ include: { roster: { only: :participant_properties } } })),
           status: :ok
  end

  def create
    hunt = current_roster.hunts.build(hunt_params)
    save_and_render_resource(authorize(hunt), json_opts: AS_JSON_OPTIONS)
  end

  def update
    @hunt.assign_attributes(hunt_params)
    save_and_render_resource(authorize(@hunt), json_opts: AS_JSON_OPTIONS)
  end

  def destroy
    destroy_and_render_resource(@hunt)
  end

  private

  def hunt_params
    params.require(:hunt).permit(:name)
  end

  def prepare_hunt
    @hunt ||= Hunt.find_by(id: params[:id])
    head :not_found unless @hunt
  end

  def authorize_hunt
    authorize @hunt
  end
end

class Api::V1::HuntsController < ApplicationController
  include Api::V1::Rosters

  before_action :authenticate_user!
  # This will make sure that the current roster is set,
  # if not render 404 before action is called.
  before_action :current_roster, only: %i[index create]
  before_action :prepare_hunt, except: %i[index create]

  def index
    render json: current_roster.hunts.includes(:licenses), status: :ok
  end

  def show
    render json: @hunt
             .as_json(include: { roster: { only: :participant_properties } }), status: :ok
  end

  def create
    save_and_render_resource(current_roster.hunts.build(hunt_params))
  end

  def update
    @hunt.update(hunts_params)
    render_resource(@hunt)
  end

  def destroy
    destroy_and_render_resource(@hunt)
  end

  private

  def hunt_params
    params.require(:hunt).permit(:name)
  end

  def prepare_hunt
    @hunt ||= Hunt.joins(roster: :permission)
      .find_by(id: params[:id], rosters: { permission: { user_id: current_user.id } })
    head :not_found unless @hunt
  end
end

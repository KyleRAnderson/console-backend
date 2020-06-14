class Api::V1::RostersController < ApplicationController
  before_action :authenticate_user!
  before_action :prepare_roster, except: %i[index create]

  def create
    save_and_render_resource(current_user.rosters.build(roster_params))
  end

  def show
    render json: @roster, status: :ok
  end

  def index
    render json: current_user.rosters.as_json + current_user.permissions.as_json(only: :level, include: :roster)
  end

  def destroy
    destroy_and_render_resource(@roster)
  end

  private

  def roster_params
    params.require(:roster).permit(:name, participant_properties: [])
  end

  def prepare_roster
    # Reason I use find_by instead of find is because find_by sets nil when not found
    @roster ||= current_user.rosters.find_by(id: params[:id])
    head :not_found unless @roster
  end
end

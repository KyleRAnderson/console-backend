class Api::V1::RostersController < ApplicationController
  before_action :authenticate_user!
  # Prepare roster before authorizing it.
  before_action :prepare_roster, except: %i[index create]
  before_action :authorize_roster, except: %i[index create update]

  def index
    render json: policy_scope(Roster), status: :ok
  end

  def show
    render json: @roster, status: :ok
  end

  def create
    roster = current_user.rosters.build(roster_params)
    roster.permissions.build(user: current_user, level: :owner)
    save_and_render_resource(authorize(roster))
  end

  def update
    @roster.assign_attributes(roster_params)
    save_and_render_resource(authorize(@roster))
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
    @roster ||= Roster.find_by(id: params[:id])
    head :not_found unless @roster
  end

  def authorize_roster
    authorize @roster
  end
end

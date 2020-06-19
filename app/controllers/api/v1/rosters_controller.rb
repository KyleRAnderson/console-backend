class Api::V1::RostersController < ApplicationController
  before_action :authenticate_user!
  before_action :prepare_roster, except: %i[index create]

  def index
    render json: current_user.rosters
  end

  def show
    render json: @roster, status: :ok
  end

  def create
    roster = current_user.rosters.build(roster_params)
    roster.permissions.build(user: current_user)
    save_and_render_resource(roster)
  end

  def update
    @roster.assign_attributes(roster_params)
    authorize @roster
    save_and_render_resource(@roster)
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
    if @roster
      # Authorization on update has to be done after record is modified.
      authorize @roster unless action_name == 'update'
    else
      head :not_found
    end
  end
end

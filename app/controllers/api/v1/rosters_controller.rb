class Api::V1::RostersController < ApplicationController
  before_action :authenticate_user!
  before_action :prepare_roster, except: %i[index create]

  def create
    roster = current_user.rosters.build(roster_params)
    if roster.save
      render json: roster, status: :created
    else
      render json: roster.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: @roster, status: :ok
  end

  def index
    render json: current_user.rosters
  end

  def destroy
    if @roster.destroy
      head :no_content
    else
      render status: :internal_server_error, json: @roster.errors
    end
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

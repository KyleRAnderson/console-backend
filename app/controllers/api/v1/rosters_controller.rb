class Api::V1::RostersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, except: [:index]

  def create
    roster = Roster.create(roster_params)
    if roster
      render json: roster
    else
      render json: roster.errors
    end
  end

  def show
    if self.roster
      render json: self.roster
    else
      render json: self.roster.errors
    end
  end

  def index
    rosters = current_user.rosters
    render json: rosters
  end

  def destroy
    begin
      self.roster&.destroy!
      render status: :ok
    rescue AciveRecord::RecordNotDestroyed => error
      render status: :internal_server_error, json: error.record.errors
    end
  end

  private
    def roster_params
      params.require(:roster).permit(:name, participant_properties: [])
    end

    def roster
      @roster ||= current_user.rosters.find(params[:id])
    end

    def correct_user
      @roster = current_user.rosters.find_by(id: params[:id])
      render json: {}, status: :not_found unless @roster
    end
end

class Api::V1::RostersController < ApplicationController
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
    rosters = Roster.all
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
      @roster ||= Roster.find(params[:id])
    end
end

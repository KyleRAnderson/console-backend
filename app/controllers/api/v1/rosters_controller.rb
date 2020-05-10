class Api::V1::RostersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, except: %i[index create]

  def create
    roster = current_user.rosters.build(roster_params)
    if roster.save
      render json: roster, status: :created
    else
      render json: roster.errors, status: :unprocessable_entity
    end
  end

  def show
    if roster
      render json: roster, status: :ok
    else
      render json: roster.errors, status: :not_found
    end
  end

  def index
    rosters = current_user.rosters
    render json: rosters
  end

  def destroy
    roster&.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotDestroyed => e
    render status: :internal_server_error, json: e.record.errors
  end

  private

  def roster_params
    params.require(:roster).permit(:name, participant_properties: [])
  end

  def roster
    # Reason I use find_by instead of find is because find_by sets nil when not found
    @roster ||= current_user.rosters.find_by(id: params[:id])
  end

  def correct_user
    @roster = current_user.rosters.find_by(id: params[:id])
    render json: { message: 'Resource not found under this user.' }, status: :not_found unless @roster
  end
end

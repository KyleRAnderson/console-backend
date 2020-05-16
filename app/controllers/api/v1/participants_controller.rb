class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters

  before_action :authenticate_user!
  before_action :current_roster
  before_action :prepare_participant, except: %i[index create]

  def index
    per_page = params.fetch(:per_page, 50)
    participants = current_roster.participants
    render json: { participants: participants.paginate(
             page: params.fetch(:page, 1),
             per_page: per_page,
           ), num_pages: (participants.count.to_f / per_page.to_i).ceil },
           status: :ok
  end

  def create
    participant = current_roster.participants.build(participant_params)
    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :internal_server_error
    end
  end

  def destroy
    if @participant.destroy
      render head :no_content
    else
      render json: @participant.errors, status: :internal_server_error
    end
  end

  def show
    render json: @participant, status: :ok
  end

  def update
    if @participant.update(participant_params)
      render json: @participant, status: :ok
    else
      render json: @participant.errors, status: :unprocessable_entity
    end
  end

  private

  def participant_params
    # Nesting strong parameters for `accepts_nested_attributes_for`:
    # https://edgeapi.rubyonrails.org/classes/ActionController/StrongParameters.html
    params.require(:participant).permit(
      :first,
      :last,
      participant_attributes_attributes: [:key, :value],
    )
  end

  def prepare_participant
    @participant ||= current_roster&.participants&.find_by(id: params[:id])
    head :not_found unless @participant
  end
end

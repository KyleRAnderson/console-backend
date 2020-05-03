class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters

  before_action :authenticate_user!
  before_action :ensure_correct_user

  def index
    render json: participant_as_json(current_roster.participants), status: :ok
  end

  def create
    participant = current_roster.participants.build(participant_params)
    if participant.save
      render json: participant_as_json(participant), status: :created
    else
      render json: participant.errors, status: :internal_server_error
    end
  end

  def destroy
    current_participant&.destroy!
    render json: participant_as_json(current_participant), status: :ok
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: e.record.errors, status: :internal_server_error
  end

  def show
    render json: participant_as_json(current_participant), status: :ok
  end

  def update
    current_participant.update!(participant_params)
    render json: participant_as_json(current_participant), status: :ok
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

  def current_participant
    @current_participant ||= current_roster.participants.find_by(id: params[:id])
  end

  def ensure_correct_user
    # If there is a participant id provided, see if it exists in the roster.
    if params[:id]
      unless current_roster&.participants&.find_by(id: params[:id])
        render json: { message: 'Participant not found on that roster' }, status: :not_found
      end
    else
      # No participant in mind, ensure that user has access to current roster.
      unless current_roster
        render json: { message: 'Roster not found under this user' }, status: :not_found
      end
    end
  end

  # Some default options for rendering participants as json, just to include their participant_attributes.
  # This method also works on collections of participants.
  def participant_as_json(participant)
    participant.as_json(include: { participant_attributes: { only: [:key, :value] } })
  end
end

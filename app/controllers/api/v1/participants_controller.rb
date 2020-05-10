class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters

  before_action :authenticate_user!
  before_action :ensure_correct_user

  def index
    per_page = params.fetch(:per_page, 50)
    participants = current_roster.participants
    render json: { participants: participants.paginate(
             page: params.fetch(:page, 1),
             per_page: per_page,
           ).as_json, num_pages: (participants.count.to_f / per_page.to_i).ceil },
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
    current_participant&.destroy!
    render head :no_content
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: e.record.errors, status: :internal_server_error
  end

  def show
    render json: current_participant, status: :ok
  end

  def update
    current_participant.update!(participant_params)
    render json: current_participant, status: :ok
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
end

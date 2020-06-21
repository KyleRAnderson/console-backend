class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters
  include Api::V1::PaginationOrdering

  before_action :authenticate_user!
  before_action :current_roster, only: %i[index create]
  before_action :prepare_participant, except: %i[index create]
  before_action :authorize_user, except: %i[index create update]

  def index
    participants = policy_scope(current_roster.participants)
    render json: paginated_ordered(participants, key: :participants), status: :ok
  end

  def show
    render json: @participant, status: :ok
  end

  def create
    participant = current_roster.participants.build(participant_params)
    save_and_render_resource(authorize(participant))
  end

  def update
    @participant.assign_attributes(participant_params)
    render_resource(authorize(@participant))
  end

  def destroy
    destroy_and_render_resource(@participant)
  end

  private

  def participant_params
    params.require(:participant).permit(:first, :last).tap do |p|
      # Need to do the hash permitting by myself.
      p[:extras] = params[:participant][:extras].permit! if params[:participant].key?(:extras)
    end
  end

  def prepare_participant
    @participant ||= Participant.find_by(id: params[:id])
    head :not_found unless @participant
  end

  def authorize_user
    authorize @participant
  end

  def ordering_params
    params.permit(:first, :last)
  end
end

class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters
  include Api::V1::PaginationOrdering

  before_action :authenticate_user!
  before_action :current_roster, only: %i[index create]
  before_action :prepare_participant, except: %i[index create]

  def index
    participants = current_roster.participants
    render json: paginated_ordered(participants, key: :participants), status: :ok
  end

  def create
    save_and_render_resource(current_roster.participants.build(participant_params))
  end

  def destroy
    destroy_and_render_resource(@participant)
  end

  def show
    render json: @participant, status: :ok
  end

  def update
    @participant.update(participant_params)
    render_resource(@participant)
  end

  private

  def participant_params
    params.require(:participant).permit(:first, :last).tap do |p|
      # Need to do the hash permitting by myself.
      p[:extras] = params[:participant][:extras].permit! if params[:participant].key?(:extras)
    end
  end

  def prepare_participant
    @participant ||= Participant.joins(:roster)
                                .find_by(id: params[:id],
                                         rosters: { user_id: current_user.id })
    head :not_found unless @participant
  end

  def ordering_params
    params.permit(:first, :last)
  end
end

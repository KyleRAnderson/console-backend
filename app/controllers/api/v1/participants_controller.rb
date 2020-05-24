class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters

  before_action :authenticate_user!
  before_action :current_roster, only: %i[index create]
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
      p[:extras] = params[:participant][:extras].permit!
    end
  end

  def prepare_participant
    @participant ||= Participant.joins(:roster)
                                .find_by(id: params[:id],
                                         rosters: { user_id: current_user.id })
    head :not_found unless @participant
  end
end

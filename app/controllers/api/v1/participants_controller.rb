class Api::V1::ParticipantsController < ApplicationController
  include Api::V1::Rosters
  include Api::V1::PaginationOrdering

  before_action :authenticate_user!
  before_action :current_roster, only: %i[index create]
  # Prepare participant before authorizing
  before_action :prepare_participant, except: %i[index create upload]
  before_action :authorize_participant, except: %i[index create update upload]

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
    save_and_render_resource(authorize(@participant))
  end

  def destroy
    destroy_and_render_resource(@participant)
  end

  def upload
    authorize current_roster, policy_class: ParticipantPolicy
    imports = Participant.csv_import(params[:file], current_roster)
    if imports.failed_instances.blank?
      head :created
    else
      render json: imports.failed_instances.map { |record| record.as_json(methods: :errors, only: %i[first last extras]) },
             status: :bad_request
    end
  rescue ArgumentError
    render plain: 'Invalid file type', status: :bad_request
  rescue CSV::MalformedCSVError
    render plain: 'Error parsing file', status: :bad_request
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

  def authorize_participant
    authorize @participant
  end

  def ordering_params
    params.permit(:first, :last)
  end
end

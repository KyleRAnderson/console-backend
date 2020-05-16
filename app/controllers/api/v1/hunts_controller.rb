class Api::V1::HuntsController < ApplicationController
  before_action :authenticate_user!
  # This will make sure that the current roster is set,
  # if not render 404 before action is called.
  before_action :current_roster
  before_action :prepare_hunt, except: %i[index create]

  def index
    render json: current_roster.hunts, status: :ok
  end

  def create
    save_and_render_resource(current_roster.hunts.build(hunt_params))
  end

  def show
    render json: json_hunt(@hunt), status: :ok
  end

  def update
    @hunt.update(hunts_params)
    render_resource(@hunt)
  end

  def destroy
    destroy_and_render_resource(@hunt)
  end

  private

  def hunt_params
    params.require(:hunt).permit(:name)
  end

  def prepare_hunt
    @hunt ||= current_roster&.hunts&.find_by(id: params[:id])
    head :not_found unless @hunt
  end
end

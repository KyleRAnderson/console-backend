class Api::V1::LicensesController < ApplicationController
  before_action :authenticate_user!
  before_action :current_hunt
  before_action :prepare_license, except: %i[index create]

  def index
    render json: current_hunt.licenses, status: :ok
  end

  def create
    save_and_render_resource(current_hunt.licenses.build(license_params))
  end

  def update
    @license.update(license_params)
    render_resource(@license)
  end

  def show
    render json: @license, status: :ok
  end

  def destroy
    destroy_and_render_resource(@license)
  end

  private

  def license_params
    params.require(:license).permit(:eliminated, :participant_id)
  end

  def prepare_license
    @license ||= current_hunt.licenses.find_by(params[:license_id])
    head :not_found unless @license
  end
end

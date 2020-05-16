class Api::V1::LicensesController < ApplicationController
  before_action :authenticate_user!
  before_action :current_hunt
  before_action :prepare_license, except: %i[index create]

  def index
    render json: current_hunt.licenses, status: :ok
  end

  def create
    license = current_hunt.licenses.build(license_params)
    if license.save
      render json: license, status: :created
    else
      render json: license.errors, status: :unprocessable_entity
    end
  end

  def update
    if @license.update(license_params)
      render json: @license, status: :ok
    else
      render json: @license.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: @license, status: :ok
  end

  def destroy
    if @license.destroy
      head :no_content
    else
      render json: @license.errors, status: :internal_server_error
    end
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

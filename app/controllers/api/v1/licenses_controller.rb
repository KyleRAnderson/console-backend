class Api::V1::LicensesController < ApplicationController
  include Api::V1::Hunts
  include Api::V1::PaginationOrdering

  before_action :authenticate_user!
  before_action :current_hunt, only: %i[index create]
  before_action :prepare_license, except: %i[index create]
  before_action :authorize_license, except: %i[index create update]

  def index
    licenses = policy_scope(current_hunt.licenses)
    render json: paginated(licenses.includes(:participant, :matches),
                           key: :licenses), status: :ok
  end

  def show
    render json: @license, status: :ok
  end

  def create
    license = current_hunt.licenses.build(license_params)
    save_and_render_resource(authorize(license))
  end

  def update
    @license.assign_attributes(license_params)
    save_and_render_resource(authorize(@license), :ok)
  end

  def destroy
    destroy_and_render_resource(@license)
  end

  private

  def license_params
    params.require(:license).permit(:eliminated, :participant_id)
  end

  def prepare_license
    @license ||= License.find_by(id: params[:id])
    head :not_found unless @license
  end

  def authorize_license
    authorize @license
  end
end

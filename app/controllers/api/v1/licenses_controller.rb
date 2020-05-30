class Api::V1::LicensesController < ApplicationController
  include Api::V1::Hunts
  include Api::V1::PaginationOrdering

  before_action :authenticate_user!
  before_action :current_hunt, only: %i[index create]
  before_action :prepare_license, except: %i[index create]

  def index
    licenses = current_hunt.licenses
    render json: paginated(licenses.includes(:participant, :matches),
                           key: :licenses), status: :ok
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
    @license ||= License.joins(hunt: :roster)
                        .find_by(id: params[:id],
                                 hunts: { rosters: { user_id: current_user.id } })
    head :not_found unless @license
  end
end

class Api::V1::LicensesController < ApplicationController
  include Api::V1::Hunts

  before_action :authenticate_user!
  before_action :current_hunt, only: %i[index create]
  before_action :prepare_license, except: %i[index create]

  def index
    per_page = params.fetch(:per_page, 25)
    licenses = current_hunt.licenses
    render json: { licenses: licenses.paginate(
             page: params.fetch(:page, 1),
             per_page: per_page,
           ).preload(:participant, :matches), num_pages: (licenses.count.to_f / per_page.to_i).ceil },
           status: :ok
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

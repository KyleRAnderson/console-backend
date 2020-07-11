class Api::V1::LicensesController < ApplicationController
  include Api::V1::Hunts
  include Api::V1::PaginationOrdering

  AS_JSON_OPTIONS = { include: { participant: { only: %i[first last extras id] } },
                      except: :participant_id, methods: :match_ids }.freeze

  before_action :authenticate_user!
  before_action :current_hunt, only: %i[index create]
  # Prepare license before authorizing it.
  before_action :prepare_license, only: %i[show update destroy]
  before_action :authorize_license, only: %i[show destroy]

  def index
    licenses = apply_search(policy_scope(apply_filters(current_hunt.licenses)))
    render json: paginated(licenses.includes(:participant, :matches), key: :licenses)
             .as_json(**AS_JSON_OPTIONS), status: :ok
  end

  def show
    render json: @license.as_json(**AS_JSON_OPTIONS), status: :ok
  end

  def create
    license = current_hunt.licenses.build(license_params)
    save_and_render_resource(authorize(license), json_opts: AS_JSON_OPTIONS)
  end

  def update
    @license.assign_attributes(license_params)
    save_and_render_resource(authorize(@license), json_opts: AS_JSON_OPTIONS)
  end

  def destroy
    destroy_and_render_resource(@license)
  end

  def eliminate_all
    authorize current_hunt, policy_class: LicensePolicy
    EliminateRemainingLicensesJob.perform_now(current_hunt)
    head :ok
  end

  def eliminate_half
    authorize current_hunt, policy_class: LicensePolicy
    EliminateHalfLicensesJob.perform_now(current_hunt.current_round)
    head :ok
  end

  private

  def license_params
    params.require(:license).permit(:eliminated, :participant_id)
  end

  def apply_filters(licenses)
    licenses = licenses.where(eliminated: params[:eliminated]) if params[:eliminated].present?
    licenses
  end

  def prepare_license
    @license ||= License.find_by(id: params[:id])
    head :not_found unless @license
  end

  def authorize_license
    authorize @license
  end

  def apply_search(licenses)
    return licenses unless params[:q].present?

    licenses.search_identifiable(params[:q])
  end
end

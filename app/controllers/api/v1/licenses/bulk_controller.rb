class Api::V1::Licenses::BulkController < ApplicationController
  include Api::V1::Hunts

  wrap_parameters :licenses, include: %i[participant_ids]

  before_action :authenticate_user!
  before_action :current_hunt

  def create
    authorize current_hunt, policy_class: Licenses::BulkPolicy
    results = License.create_for_participants(current_hunt, params.dig(:licenses, :participant_ids))
    render json: results.as_json(methods: :errors), status: results.status_code
  end
end

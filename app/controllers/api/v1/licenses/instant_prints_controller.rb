class Api::V1::Licenses::InstantPrintsController < ApplicationController
  include Api::V1::Hunts

  respond_to :json
  wrap_parameters :print, include: %i[orderings]

  before_action :authenticate_user!
  before_action :current_hunt

  # Used to download the last instant print file
  def show
  end

  # Used to create a new instant print
  # Expected body: { print: {orderings: [['<extras property name>', 'asc' | 'desc'>], ...]}}
  def create
    InstantPrintJob.perform_later(current_hunt, params.dig(:print, :orderings))
    head :accepted
  rescue ArgumentError => e
    render plain: e, status: :bad_request
  end
end

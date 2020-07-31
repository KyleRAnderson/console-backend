class Api::V1::Licenses::InstantPrintsController < ApplicationController
  include Api::V1::Hunts

  respond_to :json
  wrap_parameters :print, include: %i[orderings message]

  before_action :authenticate_user!
  before_action :current_hunt

  # Used to create a new instant print
  # Expected body: { print: {orderings: [['<extras property name>', 'asc' | 'desc'>], ...], message: 'A custom message'}}
  def create
    InstantPrintJob.perform_later(current_hunt, params.dig(:print, :orderings), params.dig(:print, :message))
    head :accepted
  rescue ArgumentError => e
    render plain: e, status: :bad_request
  end
end

class Api::V1::LandingController < ApplicationController
  def index
    render json: { name: 'Hunt Console' }
  end
end

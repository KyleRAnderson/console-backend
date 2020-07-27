class Api::V1::Hunts::TemplatePdfsController < ApplicationController
  include Api::V1::Hunts

  before_action :authenticate_user!
  before_action :authorize_hunt
  before_action :current_hunt

  def create
    if params.dig(:template_pdf).present?
      current_hunt.template_pdf.attach(params[:template_pdf])
      render json: { url: url_for(current_hunt.template_pdf) }, status: :ok
    else
      render plain: 'Need to attach template_pdf!', status: :bad_request
    end
  end

  def destroy
    current_hunt.template_pdf.purge
    head :ok
  end

  private

  def authorize_hunt
    authorize current_hunt, :update?
  end
end

class Api::V1::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  protected

  def build_resource(sign_up_params)
    super(sign_up_params).tap { |user| user.confirmation_url_store = 'testing ' }
  end
end

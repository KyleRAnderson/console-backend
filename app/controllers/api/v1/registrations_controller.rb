class Api::V1::RegistrationsController < Devise::RegistrationsController
  include ActionController::MimeResponds

  respond_to :json
end

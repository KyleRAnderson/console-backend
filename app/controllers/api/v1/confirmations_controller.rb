class Api::V1::ConfirmationsController < Devise::ConfirmationsController
  include ActionController::MimeResponds

  respond_to :json
end

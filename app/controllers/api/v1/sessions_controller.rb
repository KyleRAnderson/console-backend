class Api::V1::SessionsController < Devise::SessionsController
  include ActionController::MimeResponds

  respond_to :json
end

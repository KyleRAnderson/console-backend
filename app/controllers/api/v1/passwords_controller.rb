class Api::V1::PasswordsController < Devise::PasswordsController
  include ActionController::MimeResponds

  respond_to :json
end

class Api::V1::SessionsController < Devise::SessionsController
  include ActionController::MimeResponds

  # Allow users to login, and then afterwards we must prevent CSRF attacks.
  skip_forgery_protection only: [:create]

  respond_to :json
end

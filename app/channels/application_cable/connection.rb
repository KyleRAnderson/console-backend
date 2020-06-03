module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:auth_token].split(' ').last
      # decoded_token = JsonWebToken.decode(token)
      decoded_token = JWT.decode(token, ENV['DEVISE_JWT_SECRET_KEY'], true, algorithm: 'HS256', verify_jti: true)[0]
      if (current_user = User.find(decoded_token['sub']))
        current_user
      else
        reject_unauthorized_connection
      end
    rescue
      reject_unauthorized_connection
    end
  end
end

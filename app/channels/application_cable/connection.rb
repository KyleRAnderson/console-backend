module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      puts "Current user is now set for #{self.current_user.email}" # FIXME remove
    end

    private

    def find_verified_user
      token = request.headers[:HTTP_SEC_WEBSOCKET_PROTOCOL].split(' ').last
      puts "Token #{token}" # FIXME remove
      # decoded_token = JsonWebToken.decode(token)
      decoded_token = JWT.decode(token, ENV['DEVISE_JWT_SECRET_KEY'], true, algorithm: 'HS256', verify_jti: true)[0]
      puts "Decoded token: #{decoded_token}" # FIXME
      if (current_user = User.find(decoded_token['sub']))
        puts "Current user: #{current_user.email}" # FIXME
        current_user
      else
        reject_unauthorized_connection
      end
    rescue
      reject_unauthorized_connection
    end

    # def find_verified_user
    #   unless request.headers.key?('Authorization') && request.headers['Authorization'].split(' ').size > 1
    #     reject_unauthorized_connection
    #   end

    #   token = request.headers['Authorization'].split(' ')[1]
    #   jwt = JWT.decode(token, Rails.application.credentials.jwt_key, true, algorithm: 'HS256', verify_jti: true)[0]

    #   if (user = User.find(jwt['id']))
    #     user
    #   else
    #     reject_unauthorized_connection
    #   end
    # end
  end
end

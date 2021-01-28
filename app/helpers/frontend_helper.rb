# frozen_string_literal: true

module FrontendHelper
  public

  private

  FRONTEND_HOST_ENVIRONMENT_VARIABLE = 'FRONTEND_HOST_URL'

  def self.generate_url_helper(path, name)
    self.define_singleton_method "#{name}_url" do |**kwargs|
      new_paths = path.sub(/^\//, '').split(/\/+/).map do |segment|
        next nil unless segment.present?
        next segment unless /:.+/.match?(segment)

        if (param_value = kwargs.delete(segment[1..].to_sym)).present?
          param_value
        else
          raise ArgumentError.new("Missing value for route parameter #{segment}")
        end
      end
      [Rails.application.config.frontend_host_url.sub(/\/+$/, ''), *new_paths].join('/')
    end
  end
  [['/confirmation/:confirmation_token', 'frontend_user_confirmation'],
   ['/reset_password/:confirmation_token', 'frontend_user_password_reset'],
   ['/app/hunts/:hunt_id/matches/show/:match_id', 'frontend_match_view']].each { |path, name| generate_url_helper(path, name) }
end

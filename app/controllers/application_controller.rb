class ApplicationController < ActionController::API
  include Pundit
  include ::ActionController::MimeResponds
  include ::ActionController::Cookies
  include ::ActionController::RequestForgeryProtection

  respond_to :json

  protect_from_forgery with: :exception
  # TODO would like to find a better solution for this, see https://gitlab.com/hunt-console/console-backend/-/issues/2.
  self.allow_forgery_protection = false if Rails.env.test?

  after_action :set_csrf_cookie
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized_access

  protected

  # Custom CSRF stuff, since frontend pages are cached and will
  # have expired tokens unless refreshed.
  # See https://gitlab.com/hunt-console/console/-/issues/5.
  # Also see https://stackoverflow.com/a/15056471/7309070 as for some tips on how it's a bad idea to set this
  # unless the user has a session
  def set_csrf_cookie
    cookies['X-CSRF-Token'] = form_authenticity_token if user_signed_in?
  end

  def save_and_render_resource(resource, **options)
    resource.save
    unless options.key?(:status)
      options[:status] = action_name == 'create' ? :created : :ok
    end
    render_resource(resource, **options)
  end

  def render_resource(resource, status: :ok, json_opts: {})
    if resource.errors.empty?
      render json: resource.as_json(**json_opts), status: status
    else
      validation_error(resource)
    end
  end

  def destroy_and_render_resource(resource)
    if resource.destroy
      head :no_content
    else
      render json: resource.errors, status: :internal_server_error
    end
  end

  def validation_error(resource)
    render json: {
      message: 'Validation errors',
      detail: resource.errors,
    }, status: :unprocessable_entity
  end

  def unauthorized_access
    if %w[index show].include?(action_name)
      head :not_found
    else
      head :forbidden
    end
  end
end

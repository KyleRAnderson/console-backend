class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  def save_and_render_resource(resource, status = :created)
    resource.save
    render_resource(resource, status)
  end

  def render_resource(resource, status = :ok)
    if resource.errors.empty?
      render json: resource, status: status
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
      status: '400',
      title: 'Bad Request',
      detail: resource.errors,
    }, status: :bad_request
  end
end

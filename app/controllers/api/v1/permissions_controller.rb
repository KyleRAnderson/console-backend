class Api::V1::PermissionsController < ApplicationController
  wrap_parameters :permission, include: %i[email level]

  before_action :authenticate_user!
  before_action :current_roster, only: %i[index create]
  # Order for the next two matter, authorize permission after finding it.
  before_action :prepare_permission, except: %i[index create]
  before_action :authorize_permission, except: %i[index create update]

  include Api::V1::Rosters
  include Api::V1::PaginationOrdering

  def index
    permissions = policy_scope(current_roster.permissions)
    render json: paginated(permissions, key: :permissions), status: :ok
  end

  def show
    render json: @permission, status: :ok
  end

  def create
    permission = current_roster.permissions.build(level: params[:permission][:level], user: user)
    save_and_render_resource(authorize(permission))
  end

  def update
    @permission.assign_attributes(permission_params)
    save_and_render_resource(authorize(@permission))
  end

  def destroy
    destroy_and_render_resource(@permission)
  end

  private

  def permission_params
    params.require(:permission).permit(:level)
  end

  def prepare_permission
    @permission ||= Permission.find_by(id: params[:id])
    head :not_found unless @permission
  end

  def user
    @user ||= User.find_by(email: params[:permission][:email])
  end

  def authorize_permission
    authorize @permission
  end
end

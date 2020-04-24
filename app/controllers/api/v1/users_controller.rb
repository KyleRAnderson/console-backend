class Api::V1::UsersController < ApplicationController
  def create
    user = User.create(user_params)
    if user
      render json: user
    else
      render json: user.errors
    end
  end

  def show
    if self.user
      render json: self.user
    else
      render json: self.user.errors
    end
  end

  def destroy
    begin
      self.user&.destroy!
      render status: :ok
    rescue AciveRecord::RecordNotDestroyed => error
      render status: :internal_server_error, json: error.record.errors
    end
  end

  def index
    users = User.all.order(created_at: :desc)
    render json: users
  end

  private

    def user_params
      params.permit(:name, :email)
    end
    
    def user
      @user ||= User.find(params[:id]) # Only assigns to instance variable if it is unset.
    end
end

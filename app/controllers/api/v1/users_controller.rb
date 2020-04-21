class Api::V1::UsersController < ApplicationController
  def create
    user = User.create!(user_params)
    if user
      render json: user
    else
      render json: user.errors
    end
  end

  def show
    if user
      render json: user
    else
      render json: user.errors
    end
  end

  def destroy
    user&.destroy
    render json: { message: 'User erased.' }
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
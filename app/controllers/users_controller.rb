class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.includes(:children).find(params[:id])
  end
end

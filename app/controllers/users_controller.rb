class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.includes(:children).find(params[:id])
    return if @user == current_user || related_contacts.where(id: @user.id).exists?

    raise ActiveRecord::RecordNotFound
  end
end

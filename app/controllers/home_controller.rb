class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups.order(created_at: :desc)
    @people = User.includes(:children).order(:last_name, :first_name, :email)
  end
end

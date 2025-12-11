class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups.order(created_at: :desc)
  end
end

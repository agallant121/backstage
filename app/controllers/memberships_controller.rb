class MembershipsController < ApplicationController
  before_action :authenticate_user!

  def create
    group = Group.find(params[:group_id])
    group.users << current_user unless group.users.include?(current_user)
    redirect_to group, notice: "Joined group"
  end
end

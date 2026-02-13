class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :require_admin!, only: [ :destroy ]

  def create
    invitation = @group.invitations.pending.find_by(email: current_user.email.downcase)
    unless invitation
      redirect_to groups_path, alert: "You have not been invited to join this group."
      return
    end

    invitation.accept!(current_user)
    redirect_to @group, notice: "Joined group"
  end

  def destroy
    membership = @group.memberships.find(params[:id])
    if membership.user_id == current_user.id
      redirect_to @group, alert: "You cannot remove yourself from the group."
    else
      membership.destroy
      redirect_to @group, notice: "Member was removed."
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def require_admin!
    return if current_user.memberships.find_by(group: @group)&.admin?

    redirect_to @group, alert: "You are not allowed to manage members."
  end
end

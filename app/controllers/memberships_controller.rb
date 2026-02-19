class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group

  def create
    unless MembershipPolicy.new(current_user, @group).create?
      redirect_to groups_path, alert: "You have not been invited to join this group."
      return
    end

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

    unless MembershipPolicy.new(current_user, @group, membership: membership).destroy?
      message =
        if membership.user_id == current_user.id
          "You cannot remove yourself from the group."
        else
          "You are not allowed to manage members."
        end

      redirect_to @group, alert: message
      return
    end

    membership.destroy
    redirect_to @group, notice: "Member was removed."
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end
end

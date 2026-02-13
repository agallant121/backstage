class Groups::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :require_group_admin!

  MAX_INVITES_PER_REQUEST = 25
  MAX_INVITES_PER_WEEK = 100
  MAX_INVITES_TOTAL = 500

  def index
    @pending_invitations  = @group.invitations.pending.includes(:inviter).order(created_at: :desc)
    @accepted_invitations = @group.invitations.accepted.includes(:inviter).order(updated_at: :desc)
  end

  def create
    result = Groups::InviteUsers.call(
      group: @group,
      inviter: current_user,
      raw_emails: params.dig(:invitation, :emails).to_s,
      limits: {
        per_request: MAX_INVITES_PER_REQUEST,
        per_week: MAX_INVITES_PER_WEEK,
        total: MAX_INVITES_TOTAL
      }
    )

    flash[:notice] = result.notice if result.notice.present?
    flash[:alert]  = result.alert if result.alert.present?

    redirect_to group_invitations_path(@group)
  end

  def reissue
    invitation = @group.invitations.pending.find(params[:id])

    unless invitation.expired?
      redirect_to group_invitations_path(@group), alert: "This invite is still active and cannot be reissued yet."
      return
    end

    invitation.reissue!
    InvitationMailer.invite(invitation).deliver_later

    redirect_to group_invitations_path(@group), notice: "Invite link reissued for #{invitation.email}."
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def require_group_admin!
    membership = current_user.memberships.find_by(group: @group)
    redirect_to @group, alert: "You must be a group admin to invite others." unless membership&.admin?
  end
end

class Groups::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :require_group_admin!

  MAX_INVITES_PER_REQUEST = 25
  MAX_INVITES_PER_WEEK = 100
  MAX_INVITES_TOTAL = 500

  def index
    @invitations = @group.invitations.order(created_at: :desc)
  end

  def create
    @invitations = @group.invitations.order(created_at: :desc)

    emails = extract_emails
    if emails.empty?
      redirect_to group_invitations_path(@group), alert: "Please provide at least one email address."
      return
    end

    if emails.size > MAX_INVITES_PER_REQUEST
      redirect_to group_invitations_path(@group),
                  alert: "Please limit invites to #{MAX_INVITES_PER_REQUEST} emails at a time."
      return
    end

    if invites_week_count + emails.size > MAX_INVITES_PER_WEEK
      redirect_to group_invitations_path(@group),
                  alert: "You have reached the weekly invite limit (#{MAX_INVITES_PER_WEEK}). Try again next week."
      return
    end

    if invites_total_count + emails.size > MAX_INVITES_TOTAL
      redirect_to group_invitations_path(@group),
                  alert: "You have reached the total invite limit (#{MAX_INVITES_TOTAL})."
      return
    end

    created = []
    skipped = []

    emails.each do |email|
      if already_in_inviter_groups?(email)
        skipped << "Skipped #{email} because they are already in one of your groups."
        next
      end

      if @group.invitations.pending.exists?(email: email.downcase)
        skipped << "Skipped #{email} because they already have a pending invite."
        next
      end

      if @group.users.exists?(email: email.downcase)
        skipped << "Skipped #{email} because they are already a member."
        next
      end

      invitation = @group.invitations.build(email: email, inviter: current_user)

      if invitation.save
        InvitationMailer.invite(invitation).deliver_later
        created << invitation.email
      else
        skipped << "Could not invite #{email}: #{invitation.errors.full_messages.to_sentence}."
      end
    end

    flash[:notice] = "Invited #{created.join(', ')}" if created.any?
    flash[:alert] = skipped.join("\n") if skipped.any?

    redirect_to group_invitations_path(@group)
  end

  private

  def extract_emails
    raw = params.dig(:invitation, :emails).to_s
    raw
      .split(/[\s,;]/)
      .map { |email| email.strip.downcase }
      .reject(&:blank?)
      .uniq
  end

  def set_group
    @group = current_user.groups.find(params[:group_id])
  end

  def require_group_admin!
    membership = current_user.memberships.find_by(group: @group)
    redirect_to @group, alert: "You must be a group admin to invite others." unless membership&.admin?
  end

  def already_in_inviter_groups?(email)
    user = User.find_by(email: email)
    return false if user.nil?

    (user.group_ids & current_user.group_ids).any?
  end

  def invites_week_count
    current_user.sent_invitations.where("created_at >= ?", Time.zone.now.beginning_of_week).count
  end

  def invites_total_count
    current_user.sent_invitations.count
  end
end

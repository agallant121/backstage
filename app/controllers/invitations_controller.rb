class InvitationsController < ApplicationController
  before_action :set_invitation

  def show
    return if performed?

    if user_signed_in?
      handle_signed_in_acceptance
    else
      session[:invitation_token] = @invitation.token
      redirect_to new_user_registration_path(invite_token: @invitation.token)
    end
  end

  private

  def handle_signed_in_acceptance
    if current_user.email.casecmp?(@invitation.email)
      if @invitation.pending?
        @invitation.accept!(current_user)
        flash[:notice] = "You have been added to #{@invitation.group.name}."
      else
        flash[:alert] = "This invitation has already been used."
      end

      redirect_to @invitation.group
    else
      sign_out(current_user)
      redirect_to new_user_registration_path(invite_token: @invitation.token),
                  alert: "Please sign up or sign in with #{@invitation.email} to accept this invitation."
    end
  end

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
    return if @invitation

    redirect_to root_path, alert: "Invitation not found."
  end
end

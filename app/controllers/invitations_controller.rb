class InvitationsController < ApplicationController
  before_action :set_invitation

  def show
    return if performed?

    if user_signed_in?
      if current_user.email.casecmp?(@invitation.email)
        flash.now[:alert] = unavailable_message unless @invitation.active?
      else
        sign_out(current_user)
        redirect_to new_user_registration_path(invite_token: @invitation.token),
                    alert: "Please sign up or sign in with #{@invitation.email} to accept this invitation."
      end
    else
      session[:invitation_token] = @invitation.token
      redirect_to new_user_registration_path(invite_token: @invitation.token)
    end
  end

  def accept
    return if performed?

    unless user_signed_in?
      session[:invitation_token] = @invitation.token
      redirect_to new_user_registration_path(invite_token: @invitation.token)
      return
    end

    unless current_user.email.casecmp?(@invitation.email)
      sign_out(current_user)
      redirect_to new_user_registration_path(invite_token: @invitation.token),
                  alert: "Please sign up or sign in with #{@invitation.email} to accept this invitation."
      return
    end

    if @invitation.active?
      @invitation.accept!(current_user)
      redirect_to @invitation.group, notice: "You have been added to #{@invitation.group.name}."
    else
      redirect_to root_path, alert: unavailable_message
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
    return if @invitation

    redirect_to root_path, alert: "Invitation not found."
  end

  def unavailable_message
    @invitation.expired? ? "This invitation has expired. Please ask for a new invite link." : "This invitation has already been used."
  end
end

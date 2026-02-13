class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @group = invitation.group
    @inviter = invitation.inviter
    @accept_url = invitation_url(invitation.token)
    @expires_at = invitation.expires_at

    mail(to: invitation.email, subject: "You're invited to join #{@group.name}")
  end
end

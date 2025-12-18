class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @group = invitation.group
    @inviter = invitation.inviter
    @accept_url = invitation_url(invitation.token)

    mail(to: invitation.email, subject: "You're invited to join #{@group.name}")
  end
end

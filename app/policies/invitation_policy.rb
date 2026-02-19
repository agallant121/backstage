class InvitationPolicy < ApplicationPolicy
  attr_reader :user, :invitation

  def initialize(user, invitation)
    super
    @invitation = invitation
  end

  def accept?
    user.present? && invitation.active? && user.email.casecmp?(invitation.email)
  end
end

class MembershipPolicy < ApplicationPolicy
  attr_reader :user, :group, :membership

  def initialize(user, group, membership: nil)
    super
    @group = group
    @membership = membership
  end

  def create?
    return false unless user

    group.invitations.pending.exists?(email: user.email.downcase)
  end

  def destroy?
    return false unless user

    return false unless user.memberships.find_by(group: group)&.admin?

    membership.user_id != user.id
  end
end

class GroupInvitationPolicy < ApplicationPolicy
  attr_reader :user, :group

  def initialize(user, group)
    super
    @group = group
  end

  def create?
    admin?
  end

  def reissue?
    admin?
  end

  private

  def admin?
    return false unless user

    user.memberships.find_by(group: group)&.admin?
  end
end

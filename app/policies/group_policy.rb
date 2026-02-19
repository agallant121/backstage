class GroupPolicy < ApplicationPolicy
  attr_reader :user, :group

  def initialize(user, group)
    super
    @group = group
  end

  def create?
    user.present?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    return false unless user

    user.memberships.find_by(group: group)&.admin?
  end
end

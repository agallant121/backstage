class PostPolicy < ApplicationPolicy
  attr_reader :user, :post

  def initialize(user, post)
    super
    @post = post
  end

  def create?(group_ids:)
    return false unless user
    return false if group_ids.blank?

    user_group_ids = user.groups.where(id: group_ids).pluck(:id)
    user_group_ids.sort == group_ids.sort
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user.present? && post.user_id == user.id
  end
end

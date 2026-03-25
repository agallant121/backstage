class Group < ApplicationRecord
  has_many :memberships
  has_many :users, through: :memberships

  has_many :post_groups, dependent: :destroy
  has_many :posts, through: :post_groups
  has_many :invitations, dependent: :destroy

  SUMMARY_POST_LIMIT = 12

  def has_any_invitations?
    invitations.exists?
  end

  def refresh_message_summary_later
    GroupMessageSummaryJob.perform_later(id)
  end

  def recent_posts_for_summary(limit: SUMMARY_POST_LIMIT)
    posts
      .includes(:user)
      .order(created_at: :desc)
      .limit(limit)
  end
end

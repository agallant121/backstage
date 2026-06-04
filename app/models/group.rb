class Group < ApplicationRecord
  has_many :memberships
  has_many :users, through: :memberships

  has_many :post_groups, dependent: :destroy
  has_many :posts, through: :post_groups
  has_many :invitations, dependent: :destroy

  SUMMARY_POST_LIMIT = 12
  SUMMARY_REFRESH_DEBOUNCE = 5.minutes

  def has_any_invitations?
    invitations.exists?
  end

  def refresh_message_summary_later
    mark_message_summary_stale!
    return false if message_summary_refresh_enqueued_at.present? &&
                    message_summary_refresh_enqueued_at > SUMMARY_REFRESH_DEBOUNCE.ago

    update_column(:message_summary_refresh_enqueued_at, Time.current)
    GroupMessageSummaryJob.perform_later(id)
    true
  end

  def recent_posts_for_summary(limit: SUMMARY_POST_LIMIT)
    posts
      .includes(:user)
      .order(created_at: :desc)
      .limit(limit)
  end

  def message_summary_refresh_needed?
    message_summary_stale_at.present? ||
      (message_summary_source.nil? && message_summary_generated_at.blank?)
  end

  def clear_message_summary_refresh_state!
    update_columns(message_summary_stale_at: nil, message_summary_refresh_enqueued_at: nil)
  end

  private

  def mark_message_summary_stale!
    update_column(:message_summary_stale_at, Time.current)
  end
end

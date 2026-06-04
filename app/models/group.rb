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

  def enqueue_message_summary_refresh
    refresh_enqueued = false

    with_lock do
      now = Time.current
      if message_summary_refresh_enqueued_at.present? &&
         message_summary_refresh_enqueued_at > SUMMARY_REFRESH_DEBOUNCE.ago
        update!(message_summary_stale_at: now)
      else
        update!(message_summary_stale_at: now, message_summary_refresh_enqueued_at: now)
        refresh_enqueued = true
      end
    end

    GroupMessageSummaryJob.perform_later(id) if refresh_enqueued
    refresh_enqueued
  end

  def recent_posts_for_summary(limit: SUMMARY_POST_LIMIT)
    posts
      .order(created_at: :desc)
      .limit(limit)
  end

  def message_summary_refresh_needed?
    message_summary_stale_at.present? ||
      (message_summary_source.nil? && message_summary_generated_at.blank?)
  end

  def clear_message_summary_refresh_state!
    update!(message_summary_stale_at: nil, message_summary_refresh_enqueued_at: nil)
  end
end

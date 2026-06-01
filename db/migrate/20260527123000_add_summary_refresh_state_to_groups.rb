class AddSummaryRefreshStateToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :message_summary_stale_at, :datetime
    add_column :groups, :message_summary_refresh_enqueued_at, :datetime
  end
end

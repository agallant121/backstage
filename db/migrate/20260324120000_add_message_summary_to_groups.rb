class AddMessageSummaryToGroups < ActiveRecord::Migration[8.0]
  def change
    change_table :groups, bulk: true do |t|
      t.text :message_summary
      t.datetime :message_summary_generated_at
      t.string :message_summary_source
    end
  end
end

require "rails_helper"

RSpec.describe Group do
  describe "#refresh_message_summary_later?" do
    it "marks the summary stale and enqueues a refresh" do
      group = described_class.create!(name: "Crew")

      allow(GroupMessageSummaryJob).to receive(:perform_later)

      expect(group.refresh_message_summary_later?).to be(true)

      group.reload
      expect(group.message_summary_stale_at).to be_present
      expect(group.message_summary_refresh_enqueued_at).to be_present
      expect(GroupMessageSummaryJob).to have_received(:perform_later).with(group.id)
    end

    it "does not enqueue another refresh while one is pending" do
      group = described_class.create!(
        name: "Crew",
        message_summary_stale_at: 1.minute.ago,
        message_summary_refresh_enqueued_at: 1.minute.ago
      )

      allow(GroupMessageSummaryJob).to receive(:perform_later)

      expect(group.refresh_message_summary_later?).to be(false)

      expect(group.reload.message_summary_stale_at).to be_present
      expect(GroupMessageSummaryJob).not_to have_received(:perform_later)
    end
  end
end

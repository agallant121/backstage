require "rails_helper"

RSpec.describe Groups::MessageSummaryGenerator do
  describe "#call" do
    it "marks the summary unavailable when no OpenAI key is configured" do
      group = Group.create!(name: "Crew")
      jess = User.create!(email: "jess@example.com", password: "password", confirmed_at: Time.current, first_name: "Jess")
      alex = User.create!(email: "alex@example.com", password: "password", confirmed_at: Time.current, first_name: "Alex")

      Membership.create!(user: jess, group: group)
      Membership.create!(user: alex, group: group)

      first_post = Post.create!(user: jess, body: "Wrapped up the school fundraiser and shared the numbers.")
      second_post = Post.create!(user: alex, body: "Booked flights for next month's trip and sent the itinerary.")

      PostGroup.create!(post: first_post, group: group)
      PostGroup.create!(post: second_post, group: group)

      allow(Ai::ChatClient).to receive(:available?).and_return(false)

      described_class.new(group: group).call

      expect(group.reload.message_summary_source).to eq("unavailable")
      expect(group.message_summary).to be_nil
      expect(group.message_summary_generated_at).to be_nil
    end

    it "clears the summary when the group has no posts" do
      group = Group.create!(
        name: "Crew",
        message_summary: "Old summary",
        message_summary_generated_at: 1.day.ago,
        message_summary_source: "openai"
      )

      allow(Ai::ChatClient).to receive(:available?).and_return(false)

      described_class.new(group: group).call

      group.reload
      expect(group.message_summary).to be_nil
      expect(group.message_summary_source).to be_nil
      expect(group.message_summary_generated_at).to be_present
    end

    it "stores an AI-generated natural-language summary when available" do
      group = Group.create!(name: "Crew")
      jess = User.create!(email: "jess@example.com", password: "password", confirmed_at: Time.current, first_name: "Jess")
      alex = User.create!(email: "alex@example.com", password: "password", confirmed_at: Time.current, first_name: "Alex")

      Membership.create!(user: jess, group: group)
      Membership.create!(user: alex, group: group)

      PostGroup.create!(post: Post.create!(user: jess, body: "Wrapped up the school fundraiser and shared the numbers."), group: group)
      PostGroup.create!(post: Post.create!(user: alex, body: "Booked flights for next month's trip and sent the itinerary."), group: group)

      allow(Ai::ChatClient).to receive(:available?).and_return(true)
      allow_any_instance_of(Ai::ChatClient).to receive(:summarize).and_return(
        "Jess wrapped up the fundraiser, and Alex got next month's travel plans locked in, so the group now has both the final numbers and the itinerary."
      )

      described_class.new(group: group).call

      group.reload
      expect(group.message_summary_source).to eq("openai")
      expect(group.message_summary).to include("travel plans locked in")
      expect(group.message_summary_generated_at).to be_present
    end
  end
end

require "rails_helper"

RSpec.describe Groups::MessageSummaryGenerator do
  def create_member(email:, group:, first_name:)
    user = User.create!(email: email, password: "password", confirmed_at: Time.current, first_name: first_name)
    Membership.create!(user: user, group: group)
    user
  end

  def create_group_post(group:, user:, body:)
    PostGroup.create!(post: Post.create!(user: user, body: body), group: group)
  end

  def fundraiser_update
    "Wrapped up the school fundraiser and shared the numbers."
  end

  def travel_update
    "Booked flights for next month's trip and sent the itinerary."
  end

  def ai_summary
    "Jess wrapped up the fundraiser, and Alex got next month's travel plans locked in, " \
      "so the group now has both the final numbers and the itinerary."
  end

  describe "#call" do
    it "marks the summary unavailable when no OpenAI key is configured" do
      group = Group.create!(name: "Crew")
      jess = create_member(email: "jess@example.com", group: group, first_name: "Jess")
      alex = create_member(email: "alex@example.com", group: group, first_name: "Alex")
      create_group_post(group: group, user: jess, body: fundraiser_update)
      create_group_post(group: group, user: alex, body: travel_update)

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
      jess = create_member(email: "jess@example.com", group: group, first_name: "Jess")
      alex = create_member(email: "alex@example.com", group: group, first_name: "Alex")
      create_group_post(group: group, user: jess, body: fundraiser_update)
      create_group_post(group: group, user: alex, body: travel_update)
      client = instance_double(Ai::ChatClient, summarize: ai_summary)

      allow(Ai::ChatClient).to receive_messages(available?: true, new: client)

      described_class.new(group: group).call

      group.reload
      expect(group.message_summary_source).to eq("openai")
      expect(group.message_summary).to include("travel plans locked in")
      expect(group.message_summary_generated_at).to be_present
    end
  end
end

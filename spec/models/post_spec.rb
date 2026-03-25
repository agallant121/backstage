require "rails_helper"

RSpec.describe Post do
  let(:user) { User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current) }

  describe "validations" do
    it "requires a body when no attachments are present" do
      post = described_class.new(user: user, body: nil)

      expect(post).not_to be_valid
      expect(post.errors[:base]).to include("Add a message or at least one attachment")
    end

    it "allows attachments in place of a body" do
      post = described_class.new(user: user, body: nil)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("data"),
        filename: "image.png",
        content_type: "image/png"
      )

      post.images.attach(blob)

      expect(post).to be_valid
    end
  end

  describe ".visible_to" do
    it "returns posts in the user's groups" do
      group = Group.create!(name: "Group A")
      Membership.create!(group: group, user: user)

      visible_post = described_class.create!(user: user, body: "Hello")
      hidden_post = described_class.create!(
        user: User.create!(email: "other@example.com", password: "password", confirmed_at: Time.current),
        body: "Hidden"
      )

      PostGroup.create!(post: visible_post, group: group)
      PostGroup.create!(post: hidden_post, group: Group.create!(name: "Group B"))

      expect(described_class.visible_to(user)).to contain_exactly(visible_post)
    end
  end

  describe "summary refresh callbacks" do
    it "refreshes attached group summaries when the body changes" do
      group = Group.create!(name: "Group A")
      Membership.create!(group: group, user: user)
      post = described_class.create!(user: user, body: "Original")
      PostGroup.create!(post: post, group: group)

      allow(GroupMessageSummaryJob).to receive(:perform_later)

      post.update!(body: "Updated")

      expect(GroupMessageSummaryJob).to have_received(:perform_later).with(group.id)
    end
  end
end

require "rails_helper"

RSpec.describe PostGroup do
  it "enforces uniqueness of post within a group" do
    user = User.create!(email: "poster@example.com", password: "password", confirmed_at: Time.current)
    post = Post.create!(user: user, body: "Hello")
    group = Group.create!(name: "Group")

    described_class.create!(post: post, group: group)
    duplicate = described_class.new(post: post, group: group)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:post_id]).to include("has already been taken")
  end

  it "refreshes the group's summary when a post is added to the group" do
    user = User.create!(email: "poster@example.com", password: "password", confirmed_at: Time.current)
    post = Post.create!(user: user, body: "Hello")
    group = Group.create!(name: "Group")

    allow(GroupMessageSummaryJob).to receive(:perform_later)

    described_class.create!(post: post, group: group)

    expect(GroupMessageSummaryJob).to have_received(:perform_later).with(group.id)
  end
end

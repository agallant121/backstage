require "rails_helper"

RSpec.describe PostPolicy do
  it "allows create when all target groups belong to the user" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: user, group: group)

    policy = described_class.new(user, Post.new)

    expect(policy.create?(group_ids: [group.id])).to be(true)
  end

  it "denies create when any target group is outside the user's groups" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    owned = Group.create!(name: "Owned")
    outsider = Group.create!(name: "Outsider")
    Membership.create!(user: user, group: owned)

    policy = described_class.new(user, Post.new)

    expect(policy.create?(group_ids: [owned.id, outsider.id])).to be(false)
  end

  it "allows post owner to update and destroy" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    post_record = Post.create!(user: user, body: "Body")

    policy = described_class.new(user, post_record)

    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
  end

  it "denies non-owner from update and destroy" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    outsider = User.create!(email: "other@example.com", password: "password", confirmed_at: Time.current)
    post_record = Post.create!(user: user, body: "Body")

    policy = described_class.new(outsider, post_record)

    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end
end

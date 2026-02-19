require "rails_helper"

RSpec.describe GroupInvitationPolicy do
  it "allows admins to create and reissue invites" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: admin, group: group, role: :admin)

    policy = described_class.new(admin, group)

    expect(policy.create?).to be(true)
    expect(policy.reissue?).to be(true)
  end

  it "denies non-admin members" do
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: member, group: group)

    policy = described_class.new(member, group)

    expect(policy.create?).to be(false)
    expect(policy.reissue?).to be(false)
  end
end

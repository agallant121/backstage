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

    expect(policy).not_to be_create
    expect(policy).not_to be_reissue
  end

  it "denies admins from other groups to enforce cross-group boundaries" do
    outsider_admin = User.create!(email: "outsider-admin@example.com", password: "password", confirmed_at: Time.current)
    target_group = Group.create!(name: "Target Group")
    outsider_group = Group.create!(name: "Outsider Group")

    Membership.create!(user: outsider_admin, group: outsider_group, role: :admin)

    policy = described_class.new(outsider_admin, target_group)

    expect(policy).not_to be_create
    expect(policy).not_to be_reissue
  end
end

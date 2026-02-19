require "rails_helper"

RSpec.describe MembershipPolicy do
  it "allows join when pending invitation exists for the user email" do
    inviter = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    user = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    Invitation.create!(group: group, inviter: inviter, email: user.email)

    expect(described_class.new(user, group).create?).to be(true)
  end

  it "denies join without invitation" do
    user = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")

    expect(described_class.new(user, group).create?).to be(false)
  end

  it "allows admins to remove other members but not themselves" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: admin, group: group, role: :admin)
    member_membership = Membership.create!(user: member, group: group)
    admin_membership = Membership.find_by!(user: admin, group: group)

    expect(described_class.new(admin, group, membership: member_membership).destroy?).to be(true)
    expect(described_class.new(admin, group, membership: admin_membership).destroy?).to be(false)
  end
end

require "rails_helper"

RSpec.describe GroupPolicy do
  it "allows any signed-in user to create groups" do
    user = User.create!(email: "owner@example.com", password: "password", confirmed_at: Time.current)

    expect(described_class.new(user, Group.new).create?).to be(true)
  end

  it "allows only group admins to update and destroy groups" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: admin, group: group, role: :admin)
    Membership.create!(user: member, group: group)

    expect(described_class.new(admin, group).update?).to be(true)
    expect(described_class.new(admin, group).destroy?).to be(true)
    expect(described_class.new(member, group).update?).to be(false)
    expect(described_class.new(member, group).destroy?).to be(false)
  end
end

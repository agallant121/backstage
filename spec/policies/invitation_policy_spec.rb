require "rails_helper"

RSpec.describe InvitationPolicy do
  it "allows accepting active invitation when signed-in user email matches" do
    inviter = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    invited = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: invited.email)

    expect(described_class.new(invited, invitation).accept?).to be(true)
  end

  it "denies accepting expired invitation" do
    inviter = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    invited = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: invited.email, expires_at: 1.day.ago)

    expect(described_class.new(invited, invitation).accept?).to be(false)
  end
end

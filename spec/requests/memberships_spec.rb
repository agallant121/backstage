require "rails_helper"

RSpec.describe "Memberships", type: :request do
  it "allows invited users to join a group" do
    inviter = User.create!(email: "inviter@example.com", password: "password")
    invited_user = User.create!(email: "guest@example.com", password: "password")
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    Invitation.create!(group: group, inviter: inviter, email: invited_user.email)

    sign_in invited_user, scope: :user

    post group_memberships_path(group)

    expect(response).to redirect_to(group)
    expect(Membership.exists?(user: invited_user, group: group)).to be(true)
  end

  it "blocks users without an invitation from joining a group" do
    user = User.create!(email: "user@example.com", password: "password")
    group = Group.create!(name: "Private Group")

    sign_in user, scope: :user

    post group_memberships_path(group)

    expect(response).to redirect_to(groups_path)
    expect(flash[:alert]).to eq("You have not been invited to join this group.")
    expect(Membership.exists?(user: user, group: group)).to be(false)
  end
end

require "rails_helper"

RSpec.describe "Invitations" do
  it "adds the user to the group when accepting" do
    inviter = User.create!(email: "inviter@example.com", password: "password")
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: "guest@example.com")
    invited_user = User.create!(email: "guest@example.com", password: "password")

    sign_in invited_user, scope: :user

    post accept_invitation_path(invitation.token)

    expect(response).to redirect_to(group)
    expect(invitation.reload.accepted_at).to be_present
    expect(Membership.exists?(user: invited_user, group: group)).to be(true)
  end
end

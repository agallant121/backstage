require "rails_helper"

RSpec.describe "Invitations" do
  it "adds the user to the group when accepting" do
    inviter = User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: "guest@example.com")
    invited_user = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)

    sign_in invited_user, scope: :user

    post accept_invitation_path(invitation.token)

    expect(response).to redirect_to(group)
    expect(invitation.reload.accepted_at).to be_present
    expect(Membership.exists?(user: invited_user, group: group)).to be(true)
  end

  it "forces a different signed-in user to re-authenticate as the invited email" do
    inviter = User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: "guest@example.com")
    wrong_user = User.create!(email: "other@example.com", password: "password", confirmed_at: Time.current)

    sign_in wrong_user, scope: :user

    post accept_invitation_path(invitation.token)

    expect(response).to redirect_to(new_user_registration_path(invite_token: invitation.token))
    expect(flash[:alert]).to eq("Please sign up or sign in with #{invitation.email} to accept this invitation.")
    expect(Membership.exists?(user: wrong_user, group: group)).to be(false)
  end

  it "rejects accepting expired invitations" do
    inviter = User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: "guest@example.com", expires_at: 1.day.ago)
    invited_user = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)

    sign_in invited_user, scope: :user

    post accept_invitation_path(invitation.token)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("This invitation has expired. Please ask for a new invite link.")
    expect(invitation.reload.accepted_at).to be_nil
  end
end

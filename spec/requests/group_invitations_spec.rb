require "rails_helper"

RSpec.describe "Group Invitations", type: :request do
  it "blocks non-admin members from creating invitations" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")

    Membership.create!(user: admin, group: group, role: :admin)
    Membership.create!(user: member, group: group, role: :member)

    sign_in member, scope: :user

    expect do
      post group_invitations_path(group), params: { invitation: { emails: "guest@example.com" } }
    end.not_to change(Invitation, :count)

    expect(response).to redirect_to(group_path(group))
    expect(flash[:alert]).to eq("You must be a group admin to invite others.")
  end

  it "blocks members from inviting users already in one of their groups" do
    inviter = User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current)
    existing_user = User.create!(email: "existing@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")

    Membership.create!(user: inviter, group: group, role: :admin)
    Membership.create!(user: existing_user, group: group)

    sign_in inviter, scope: :user

    expect do
      post group_invitations_path(group), params: { invitation: { emails: existing_user.email } }
    end.not_to change(Invitation, :count)

    expect(response).to redirect_to(group_invitations_path(group))
    expect(flash[:alert]).to include("Skipped #{existing_user.email} because they are already in one of your groups.")
  end

  it "reissues an expired invitation token when invited again" do
    inviter = User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: "guest@example.com", expires_at: 1.day.ago)
    old_token = invitation.token

    sign_in inviter, scope: :user

    expect do
      post group_invitations_path(group), params: { invitation: { emails: invitation.email } }
    end.not_to change(Invitation, :count)

    invitation.reload

    expect(flash[:notice]).to include("Reissued invites for #{invitation.email}")
    expect(invitation.token).not_to eq(old_token)
    expect(invitation.expires_at).to be > Time.current
  end
end

require "rails_helper"

RSpec.describe "Authorization policy coverage", type: :request do
  it "blocks non-owners from editing posts" do
    author = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    viewer = User.create!(email: "viewer@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: author, group: group)
    Membership.create!(user: viewer, group: group)
    post_record = Post.create!(user: author, body: "Original")
    PostGroup.create!(post: post_record, group: group)

    sign_in viewer, scope: :user

    get edit_post_path(post_record)

    expect(response).to redirect_to(post_record)
    expect(flash[:alert]).to eq("You are not allowed to manage this post.")
  end

  it "blocks non-admin members from updating and deleting groups" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group", description: "Before")
    Membership.create!(user: admin, group: group, role: :admin)
    Membership.create!(user: member, group: group)

    sign_in member, scope: :user

    patch group_path(group), params: { group: { description: "After" } }
    expect(response).to redirect_to(group_path(group))
    expect(group.reload.description).to eq("Before")

    expect do
      delete group_path(group)
    end.not_to change(Group, :count)

    expect(response).to redirect_to(group_path(group))
  end

  it "blocks non-admin members from removing memberships" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    target = User.create!(email: "target@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: admin, group: group, role: :admin)
    Membership.create!(user: member, group: group)
    target_membership = Membership.create!(user: target, group: group)

    sign_in member, scope: :user

    expect do
      delete group_membership_path(group, target_membership)
    end.not_to change(Membership, :count)

    expect(response).to redirect_to(group_path(group))
    expect(flash[:alert]).to eq("You are not allowed to manage members.")
  end

  it "blocks expired invitation acceptance" do
    inviter = User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current)
    invited = User.create!(email: "guest@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: inviter, group: group, role: :admin)
    invitation = Invitation.create!(group: group, inviter: inviter, email: invited.email, expires_at: 1.day.ago)

    sign_in invited, scope: :user

    post accept_invitation_path(invitation.token)

    expect(response).to redirect_to(group_path(group))
    expect(invitation.reload.accepted_at).to be_nil
  end

  it "blocks non-admin members from reissuing group invitations" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    member = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group")
    Membership.create!(user: admin, group: group, role: :admin)
    Membership.create!(user: member, group: group)
    invitation = Invitation.create!(group: group, inviter: admin, email: "guest@example.com", expires_at: 1.day.ago)

    sign_in member, scope: :user

    post reissue_group_invitation_path(group, invitation)

    expect(response).to redirect_to(group_path(group))
    expect(flash[:alert]).to eq("You must be a group admin to invite others.")
  end
end

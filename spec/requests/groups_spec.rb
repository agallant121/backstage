require "rails_helper"

RSpec.describe "Groups", type: :request do
  it "creates a group and assigns the creator as admin" do
    user = User.create!(email: "owner@example.com", password: "password")

    post user_session_path, params: { user: { email: user.email, password: "password" } }

    post groups_path, params: { group: { name: "New Group", description: "About" } }

    group = Group.find_by!(name: "New Group")
    membership = Membership.find_by!(user: user, group: group)

    expect(response).to redirect_to(group)
    expect(membership).to be_admin
  end

  it "allows members to view the group members page" do
    user = User.create!(email: "member@example.com", password: "password")
    group = Group.create!(name: "Crew")
    Membership.create!(user: user, group: group)

    sign_in user

    get members_group_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Group members")
    expect(response.body).to include("member@example.com")
  end

  it "blocks non-members from viewing the members page" do
    user = User.create!(email: "member@example.com", password: "password")
    outsider = User.create!(email: "outsider@example.com", password: "password")
    group = Group.create!(name: "Crew")
    Membership.create!(user: user, group: group)

    sign_in outsider

    expect do
      get members_group_path(group)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end

require "rails_helper"

RSpec.describe "Groups", type: :request do
  def create_member(email:, group:, first_name: nil)
    user = User.create!(email: email, password: "password", confirmed_at: Time.current, first_name: first_name)
    Membership.create!(user: user, group: group)
    user
  end

  def cached_summary
    "Jess wrapped the fundraiser.\nAlex booked flights for the trip."
  end

  it "creates a group and assigns the creator as admin" do
    user = User.create!(email: "owner@example.com", password: "password", confirmed_at: Time.current)

    post user_session_path, params: { user: { email: user.email, password: "password" } }

    post groups_path, params: { group: { name: "New Group", description: "About" } }

    group = Group.find_by!(name: "New Group")
    membership = Membership.find_by!(user: user, group: group)

    expect(response).to redirect_to(group)
    expect(membership).to be_admin
  end

  it "allows members to view the group members page" do
    user = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Crew")
    Membership.create!(user: user, group: group)

    sign_in user

    get members_group_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Group members")
    expect(response.body).to include("member@example.com")
  end

  it "blocks non-members from viewing the members page" do
    user = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    outsider = User.create!(email: "outsider@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Crew")
    Membership.create!(user: user, group: group)

    sign_in outsider, scope: :user
    get members_group_path(group)

    expect(response).to have_http_status(:not_found)
  end

  it "shows the cached group summary on the group page" do
    group = Group.create!(name: "Crew", message_summary: cached_summary,
                          message_summary_generated_at: 5.minutes.ago, message_summary_source: "openai")
    user = create_member(email: "member@example.com", group: group)
    PostGroup.create!(post: Post.create!(user: user, body: "Latest update"), group: group)

    sign_in user, scope: :user
    get group_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AI recap")
    expect(response.body).to include(cached_summary.lines.first.strip)
    expect(response.body).to include(cached_summary.lines.second.strip)
  end

  it "shows an unavailable state when AI summaries are not configured" do
    user = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Crew", message_summary_source: "unavailable")

    Membership.create!(user: user, group: group)
    PostGroup.create!(post: Post.create!(user: user, body: "Latest update"), group: group)

    sign_in user, scope: :user
    get group_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AI summaries are not configured yet for this environment.")
  end
end

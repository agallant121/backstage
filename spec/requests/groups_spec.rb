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

  def create_member_list(group, count)
    count.times do |index|
      user = User.create!(email: format("member%02d@example.com", index), password: "password",
                          confirmed_at: Time.current)
      Membership.create!(user: user, group: group)
    end
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

  it "shows edit actions only for groups the user administers" do
    user = User.create!(email: "member@example.com", password: "password", confirmed_at: Time.current)
    admin_group = Group.create!(name: "Admin Crew")
    member_group = Group.create!(name: "Member Crew")
    Membership.create!(user: user, group: admin_group, role: :admin)
    Membership.create!(user: user, group: member_group)

    sign_in user, scope: :user
    get groups_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(edit_group_path(admin_group))
    expect(response.body).not_to include(edit_group_path(member_group))
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

  it "paginates the group members page" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Crew")
    Membership.create!(user: admin, group: group, role: :admin)
    create_member_list(group, 26)

    sign_in admin, scope: :user
    get members_group_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("27 members", "member00@example.com")
    expect(response.body).not_to include("member25@example.com")
  end

  it "shows later pages on the group members page" do
    admin = User.create!(email: "admin@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Crew")
    Membership.create!(user: admin, group: group, role: :admin)
    create_member_list(group, 26)

    sign_in admin, scope: :user
    get members_group_path(group, page: 2)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("member25@example.com")
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

  it "renders group posts with media attachments" do
    group = Group.create!(name: "Crew")
    user = create_member(email: "member@example.com", group: group)
    post = Post.create!(user: user, body: "Photo update")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("image data"),
      filename: "photo.png",
      content_type: "image/png"
    )
    post.images.attach(blob)
    PostGroup.create!(post: post, group: group)

    sign_in user, scope: :user
    get group_path(group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Includes photos")
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

  it "enqueues the initial summary backfill only when no summary state exists yet" do
    group = Group.create!(name: "Crew")
    user = create_member(email: "member@example.com", group: group)
    PostGroup.create!(post: Post.create!(user: user, body: "Latest update"), group: group)
    group.clear_message_summary_refresh_state!

    allow(GroupMessageSummaryJob).to receive(:perform_later)

    sign_in user, scope: :user
    get group_path(group)

    expect(GroupMessageSummaryJob).to have_received(:perform_later).with(group.id)
  end

  it "does not enqueue summary backfill for turbo post pagination" do
    group = Group.create!(name: "Crew")
    user = create_member(email: "member@example.com", group: group)
    11.times do |index|
      PostGroup.create!(post: Post.create!(user: user, body: "Latest update #{index}"), group: group)
    end
    group.clear_message_summary_refresh_state!

    allow(GroupMessageSummaryJob).to receive(:perform_later)

    sign_in user, scope: :user
    get group_path(group, page: 2, format: :turbo_stream)

    expect(response).to have_http_status(:ok)
    expect(GroupMessageSummaryJob).not_to have_received(:perform_later)
    expect(group.reload.message_summary_stale_at).to be_nil
  end

  it "does not re-enqueue summary generation for unavailable or error states" do
    %w[unavailable error].each do |summary_source|
      group = Group.create!(name: "Crew #{summary_source}", message_summary_source: summary_source)
      user = create_member(email: "#{summary_source}@example.com", group: group)
      PostGroup.create!(post: Post.create!(user: user, body: "Latest update"), group: group)

      RSpec::Mocks.space.proxy_for(GroupMessageSummaryJob).reset
      allow(GroupMessageSummaryJob).to receive(:perform_later)

      sign_in user, scope: :user
      get group_path(group)

      expect(GroupMessageSummaryJob).not_to have_received(:perform_later)
    end
  end
end

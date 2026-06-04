require "rails_helper"

RSpec.describe "Home" do
  def create_dashboard_group(user)
    group = Group.create!(name: "Crew")
    Membership.create!(user: user, group: group)
    group
  end

  def attach_post_to_group(user:, group:, body:, created_at:)
    post = Post.create!(user: user, body: body, created_at: created_at)
    PostGroup.create!(post: post, group: group)
    post
  end

  it "redirects unauthenticated users to sign in" do
    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the dashboard for signed-in users" do
    user = User.create!(email: "user@example.com", password: "password", confirmed_at: Time.current)

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Keep your circles updated without the pressure to reply.")
    expect(response.body).not_to include("Share once, reach everyone")
  end

  it "shows the latest three updates for each group" do
    user = User.create!(email: "user@example.com", password: "password", confirmed_at: Time.current)
    group = create_dashboard_group(user)
    attach_post_to_group(user: user, group: group, body: "Old update", created_at: 5.days.ago)
    3.times do |index|
      attach_post_to_group(user: user, group: group, body: "Recent update #{index + 1}",
                           created_at: (index + 1).hours.ago)
    end

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Recent update 1", "Recent update 2", "Recent update 3")
    expect(response.body).not_to include("Old update")
  end

  it "limits the dashboard group preview" do
    user = User.create!(email: "user@example.com", password: "password", confirmed_at: Time.current)

    groups = Array.new(9) do |index|
      group = Group.create!(name: "Group #{index + 1}", created_at: index.days.ago)
      Membership.create!(user: user, group: group)
      group
    end

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Showing the first 8 groups.", "View all", groups.first.name)
    expect(response.body).not_to include(groups.last.name)
  end
end

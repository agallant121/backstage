require "rails_helper"

RSpec.describe "Home" do
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
    group = Group.create!(name: "Crew")
    Membership.create!(user: user, group: group)

    old_post = Post.create!(user: user, body: "Old update", created_at: 5.days.ago)
    recent_posts = 3.times.map do |index|
      Post.create!(user: user, body: "Recent update #{index + 1}", created_at: (index + 1).hours.ago)
    end

    ([ old_post ] + recent_posts).each do |post|
      PostGroup.create!(post: post, group: group)
    end

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Recent update 1")
    expect(response.body).to include("Recent update 2")
    expect(response.body).to include("Recent update 3")
    expect(response.body).not_to include("Old update")
  end

  it "limits the dashboard group preview" do
    user = User.create!(email: "user@example.com", password: "password", confirmed_at: Time.current)

    groups = 9.times.map do |index|
      group = Group.create!(name: "Group #{index + 1}", created_at: index.days.ago)
      Membership.create!(user: user, group: group)
      group
    end

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Showing the first 8 groups.")
    expect(response.body).to include("View all")
    expect(response.body).to include(groups.first.name)
    expect(response.body).not_to include(groups.last.name)
  end
end

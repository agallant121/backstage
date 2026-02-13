require "rails_helper"

RSpec.describe "Users", type: :request do
  it "allows viewing your own profile" do
    user = User.create!(email: "self@example.com", password: "password", confirmed_at: Time.current)

    sign_in user

    get user_path(user)

    expect(response).to have_http_status(:ok)
  end

  it "allows viewing a shared-group contact profile" do
    viewer = User.create!(email: "viewer@example.com", password: "password", confirmed_at: Time.current)
    contact = User.create!(email: "contact@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Shared")

    Membership.create!(user: viewer, group: group)
    Membership.create!(user: contact, group: group)

    sign_in viewer

    get user_path(contact)

    expect(response).to have_http_status(:ok)
  end

  it "blocks viewing a user outside your groups" do
    viewer = User.create!(email: "viewer2@example.com", password: "password", confirmed_at: Time.current)
    outsider = User.create!(email: "outsider@example.com", password: "password", confirmed_at: Time.current)

    sign_in viewer

    get user_path(outsider)

    expect(response).to have_http_status(:not_found)
  end
end

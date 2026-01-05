require "rails_helper"

RSpec.describe "Groups" do
  it "creates a group and assigns the creator as admin" do
    user = User.create!(email: "owner@example.com", password: "password")

    sign_in user, scope: :user

    post groups_path, params: { group: { name: "New Group", description: "About" } }

    group = Group.find_by!(name: "New Group")
    membership = Membership.find_by!(user: user, group: group)

    expect(response).to redirect_to(group)
    expect(membership).to be_admin
  end
end

require "rails_helper"

RSpec.describe "Posts" do
  it "creates a post for all of the user's groups" do
    user = User.create!(email: "author@example.com", password: "password")
    group_one = Group.create!(name: "Group One")
    group_two = Group.create!(name: "Group Two")

    Membership.create!(user: user, group: group_one)
    Membership.create!(user: user, group: group_two)

    sign_in user

    post posts_path, params: { post: { body: "Hello" } }

    post_record = Post.find_by!(user: user, body: "Hello")

    expect(response).to redirect_to(root_path)
    expect(PostGroup.where(post: post_record).count).to eq(2)
  end
end

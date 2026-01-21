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

  it "prevents non-authors from updating or deleting posts" do
    author = User.create!(email: "author@example.com", password: "password")
    other_user = User.create!(email: "reader@example.com", password: "password")
    group = Group.create!(name: "Group One")

    Membership.create!(user: author, group: group)
    Membership.create!(user: other_user, group: group)

    post_record = Post.create!(user: author, body: "Original")
    PostGroup.create!(post: post_record, group: group)

    sign_in other_user

    patch post_path(post_record), params: { post: { body: "Updated" } }

    expect(response).to redirect_to(post_path(post_record))
    expect(post_record.reload.body).to eq("Original")

    expect do
      delete post_path(post_record)
    end.not_to change(Post, :count)

    expect(response).to redirect_to(post_path(post_record))
  end
end

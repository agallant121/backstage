require "rails_helper"

RSpec.describe "Posts" do
  it "creates a post for all of the user's groups" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    group_one = Group.create!(name: "Group One")
    group_two = Group.create!(name: "Group Two")

    Membership.create!(user: user, group: group_one)
    Membership.create!(user: user, group: group_two)

    sign_in user, scope: :user
    allow(GroupMessageSummaryJob).to receive(:perform_later)

    post posts_path, params: { post: { body: "Hello" } }

    post_record = Post.find_by!(user: user, body: "Hello")

    expect(response).to redirect_to(root_path)
    expect(PostGroup.where(post: post_record).count).to eq(2)
    expect(GroupMessageSummaryJob).to have_received(:perform_later).with(group_one.id)
    expect(GroupMessageSummaryJob).to have_received(:perform_later).with(group_two.id)
  end

  it "rolls back the post if group attachment fails" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group One")

    Membership.create!(user: user, group: group)

    sign_in user, scope: :user
    allow(PostGroup).to receive(:insert_all).and_raise(ActiveRecord::StatementInvalid)
    allow(GroupMessageSummaryJob).to receive(:perform_later)

    expect do
      post posts_path, params: { post: { body: "Hello" } }
    end.not_to change(Post, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(GroupMessageSummaryJob).not_to have_received(:perform_later)
  end

  it "only allows creating a post in one of the author's groups" do
    user = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    member_group = Group.create!(name: "Member Group")
    outsider_group = Group.create!(name: "Outsider Group")

    Membership.create!(user: user, group: member_group)

    sign_in user, scope: :user

    expect do
      post posts_path, params: { post: { body: "Hello", group_id: outsider_group.id } }
    end.not_to change(Post, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "prevents non-authors from updating or deleting posts" do
    author = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    other_user = User.create!(email: "reader@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Group One")

    Membership.create!(user: author, group: group)
    Membership.create!(user: other_user, group: group)

    post_record = Post.create!(user: author, body: "Original")
    PostGroup.create!(post: post_record, group: group)

    sign_in other_user, scope: :user

    patch post_path(post_record), params: { post: { body: "Updated" } }

    expect(response).to redirect_to(post_path(post_record))
    expect(post_record.reload.body).to eq("Original")

    expect do
      delete post_path(post_record)
    end.not_to change(Post, :count)

    expect(response).to redirect_to(post_path(post_record))
  end

  it "does not leak non-visible posts via show" do
    author = User.create!(email: "author@example.com", password: "password", confirmed_at: Time.current)
    outsider = User.create!(email: "outsider@example.com", password: "password", confirmed_at: Time.current)
    group = Group.create!(name: "Private")

    Membership.create!(user: author, group: group)

    post_record = Post.create!(user: author, body: "Private post")
    PostGroup.create!(post: post_record, group: group)

    sign_in outsider, scope: :user
    get post_path(post_record)

    expect(response).to have_http_status(:not_found)
  end
end

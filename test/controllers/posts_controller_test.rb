require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "index renders visible per-post expand controls in compact mode" do
    expandable_post = Post.create!(
      body: "Expanded post body " * 20,
      user: @user,
      groups: [ groups(:one) ]
    )

    short_post = Post.create!(
      body: "Short body",
      user: @user,
      groups: [ groups(:one) ]
    )

    get posts_path

    assert_response :success
    assert_select "button[data-action='post-expand#expand']", text: "Read full post", count: 1
    assert_includes response.body, expandable_post.body.truncate(160)
    assert_select "#post_#{short_post.id} button[data-action='post-expand#expand']", count: 0
  end
end

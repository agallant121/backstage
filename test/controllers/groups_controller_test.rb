require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @group = groups(:one)
    sign_in @user
  end

  test "show renders visible per-post expand controls in compact mode" do
    expandable_post = Post.create!(
      body: "Expanded post body " * 20,
      user: @user,
      groups: [ @group ]
    )

    short_post = Post.create!(
      body: "Short body",
      user: @user,
      groups: [ @group ]
    )

    get group_path(@group)

    assert_response :success
    assert_select "button[data-action='post-expand#expand']", text: "Read full post", count: 1
    assert_includes response.body, expandable_post.body.truncate(160)
    assert_select "#post_#{short_post.id} button[data-action='post-expand#expand']", count: 0
  end
end

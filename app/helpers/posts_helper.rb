module PostsHelper
  def can_manage_post?(post)
    user_signed_in? && post.user_id == current_user.id
  end

  def post_timestamp_label(post)
    "Shared #{time_ago_in_words(post.created_at)} ago • #{post.created_at.strftime("%b %-d, %Y")}"
  end
end

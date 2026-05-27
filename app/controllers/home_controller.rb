class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups.order(created_at: :desc).to_a
    @latest_posts_by_group = latest_posts_by_group(@groups.map(&:id))
    contacts_scope = related_contacts
    @people_total = contacts_scope.count
    @people = contacts_scope.includes(:children).order(:last_name, :first_name, :email).limit(15)
  end

  private

  def latest_posts_by_group(group_ids)
    return {} if group_ids.empty?

    ranked_post_groups = PostGroup
      .joins(:post)
      .where(group_id: group_ids)
      .select(<<~SQL.squish)
        post_groups.post_id,
        post_groups.group_id,
        ROW_NUMBER() OVER (
          PARTITION BY post_groups.group_id
          ORDER BY posts.created_at DESC, posts.id DESC
        ) AS preview_rank
      SQL

    Post
      .joins("INNER JOIN (#{ranked_post_groups.to_sql}) ranked_post_groups ON ranked_post_groups.post_id = posts.id")
      .where("ranked_post_groups.preview_rank <= 3")
      .select("posts.*, ranked_post_groups.group_id AS preview_group_id")
      .order(Arel.sql("ranked_post_groups.group_id, posts.created_at DESC, posts.id DESC"))
      .group_by { |post| post.preview_group_id.to_i }
  end
end

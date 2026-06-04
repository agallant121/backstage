class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :new, :create ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_post_mutation!, only: [ :edit, :update, :destroy ]

  def index
    @posts = Post.visible_to(current_user)
      .with_list_associations
      .order(created_at: :desc)
      .page(params[:page])
      .per(10)

    @view_mode = params[:view] == "full" ? :full : :compact

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
  end

  def new
    @post = current_user.posts.new
    set_post_form_groups
  end

  def create
    group_ids_to_attach = group_target_resolver.attach_ids
    return head :not_found if group_ids_to_attach.nil?
    return head :forbidden unless policy(Post).create?(group_ids: group_ids_to_attach)

    @post = current_user.posts.build(post_params)

    if save_post_with_groups(@post, group_ids_to_attach, "Post could not be created. Please try again.")
      redirect_to root_path, notice: "Post created."
    else
      set_post_form_groups
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_post_form_groups
  end

  def update
    group_ids_to_attach = group_target_resolver.submitted? ? group_target_resolver.attach_ids : @post.group_ids
    return head :not_found if group_ids_to_attach.nil?
    return head :forbidden unless policy(Post).create?(group_ids: group_ids_to_attach)

    if save_post_with_groups(
      @post,
      group_ids_to_attach,
      "Post could not be updated. Please try again.",
      attributes: post_params
    )
      redirect_to @post, notice: "Post was successfully updated."
    else
      set_post_form_groups
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url, notice: "Post was successfully destroyed."
  end

  private

  def set_post
    @post = Post.visible_to(current_user).find(params[:id])
  end

  def set_group
    @group = current_user.groups.find(params[:group_id]) if params[:group_id]
  end

  def set_post_form_groups
    @groups_for_select = current_user.groups.order(:name).to_a
    @selected_group_ids = selected_group_ids_for_form
  end

  def group_target_resolver
    @group_target_resolver ||= Posts::GroupTargetResolver.new(user: current_user, params: params)
  end

  def save_post_with_groups(post, group_ids, error_message, attributes: nil)
    Posts::SaveWithGroupTargets.new(
      post: post,
      group_ids: group_ids,
      attributes: attributes,
      error_message: error_message
    ).call
  end

  def selected_group_ids_for_form
    return group_target_resolver.selected_ids if group_target_resolver.submitted?
    return @post.group_ids if @post&.persisted?

    Array(@group&.id).compact
  end

  def authorize_post_mutation!
    policy = policy(@post)

    allowed =
      case action_name
      when "edit", "update" then policy.update?
      when "destroy" then policy.destroy?
      end

    return if allowed

    redirect_to @post, alert: "You are not allowed to manage this post."
  end

  def post_params
    params.require(:post).permit(:body, attachments: [])
  end
end

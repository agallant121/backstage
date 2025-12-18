class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :new, :create ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def index
    @posts = Post.visible_to(current_user).order(created_at: :desc)

    @view_mode = params[:view] == "full" ? :full : :compact
  end

  def show
  end

  def new
    @post = current_user.posts.new
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      selected_group_id = params.dig(:post, :group_id).presence

      group_ids_to_attach =
        if selected_group_id
          [ selected_group_id.to_i ]
        else
          current_user.groups.pluck(:id)
        end

      group_ids_to_attach.each do |gid|
        PostGroup.find_or_create_by!(post_id: @post.id, group_id: gid)
      end

      redirect_to root_path, notice: "Post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
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

  def post_params
    params.require(:post).permit(:body, attachments: [])
  end
end

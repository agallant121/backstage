class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :new, :create ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def index
    @posts = current_user.posts.all
  end

  def show
  end

  def new
    @post = current_user.posts.new
  end

  def create
    @post = current_user.posts.new(post_params)
    if @post.save
      redirect_to @post, notice: "Post was successfully created."
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
    @post = current_user.posts.find(params[:id])
  end

  def set_group
    @group = current_user.groups.find(params[:group_id]) if params[:group_id]
  end

  def post_params
    params.require(:post).permit(:body, :group_id, images: [])
  end
end

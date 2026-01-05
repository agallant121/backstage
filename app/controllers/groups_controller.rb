class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :show, :edit, :update, :destroy ]

  def index
    @groups = current_user.groups
      .order(:name)
      .page(params[:page])
      .per(12)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @posts = @group.posts.order(created_at: :desc)
    @view_mode = params[:view] == "full" ? :full : :compact
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    if @group.save
      membership = current_user.memberships.find_or_initialize_by(group: @group)
      membership.role = :admin
      membership.save!
      redirect_to @group, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_url, notice: "Group was successfully destroyed."
  end

  private

  def set_group
    @group = current_user.groups.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description)
  end
end

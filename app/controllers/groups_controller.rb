class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :show, :edit, :update, :destroy, :members ]
  before_action :authorize_group_mutation!, only: [ :edit, :update, :destroy ]

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
    @group.refresh_message_summary_later if should_backfill_message_summary?
  end

  def members
    @memberships = @group.memberships.includes(:user).joins(:user).order("users.email")
    @admin = current_user.memberships.find_by(group: @group)&.admin?
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    return head :forbidden unless policy(@group).create?

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

  def should_backfill_message_summary?
    @posts.exists? &&
      @group.message_summary_source.nil? &&
      @group.message_summary_generated_at.blank?
  end

  def authorize_group_mutation!
    policy = policy(@group)
    return if action_name == "edit" && policy.update?
    return if action_name == "update" && policy.update?
    return if action_name == "destroy" && policy.destroy?

    redirect_to @group, alert: "You are not allowed to manage this group."
  end
end

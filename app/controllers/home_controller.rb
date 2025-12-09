class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
  @posts = Post
             .joins(:group)
             .where(group_id: current_user.group_ids)
             .or(Post.where(user_id: current_user.id))
             .order(created_at: :desc)  
  end
end

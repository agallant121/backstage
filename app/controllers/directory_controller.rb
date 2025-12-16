class DirectoryController < ApplicationController
  before_action :authenticate_user!

  def index
    @user_groups = current_user.groups.to_a
    @query = params[:query].to_s.strip

    scoped_people = related_contacts.includes(:children, :groups)

    if @query.present?
      sanitized_query = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scoped_people = scoped_people.where(
        "users.first_name ILIKE :q OR users.last_name ILIKE :q OR CONCAT(users.first_name, ' ', users.last_name) ILIKE :q OR users.email ILIKE :q",
        q: sanitized_query
      )
    end

    @people = scoped_people
      .order(:last_name, :first_name, :email)
      .page(params[:page])
      .per(16)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end

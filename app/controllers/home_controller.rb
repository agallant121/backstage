class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups.order(created_at: :desc)
    contacts_scope = related_contacts
    @people_total = contacts_scope.count
    @people = contacts_scope.includes(:children).order(:last_name, :first_name, :email).limit(15)
  end
end

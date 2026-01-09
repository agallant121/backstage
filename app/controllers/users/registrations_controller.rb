class Users::RegistrationsController < Devise::RegistrationsController
  before_action :ensure_devise_mapping

  def new
    invitation = Invitation.find_by(token: params[:invite_token] || session[:invitation_token])
    unless invitation&.pending?
      session.delete(:invitation_token)
      redirect_to root_path, alert: "An invitation is required to sign up."
      return
    end

    session[:invitation_token] = invitation.token
    self.resource = build_resource(email: invitation.email)

    set_minimum_password_length
    respond_with resource
  end

  def create
    invitation = Invitation.find_by(token: session[:invitation_token])
    unless invitation&.pending?
      session.delete(:invitation_token)
      redirect_to root_path, alert: "An invitation is required to sign up."
      return
    end

    super do |resource|
      if resource.persisted? && invitation&.pending?
        invitation.accept!(resource)
      end
    end
  end

  private

  def after_inactive_sign_up_path_for(resource)
    invitation_redirect_path || super
  end

  def after_sign_up_path_for(resource)
    invitation_redirect_path || super
  end

  def invitation_redirect_path
    token = session.delete(:invitation_token)
    return if token.blank?

    invitation = Invitation.find_by(token: token)
    invitation&.group
  end

  def ensure_devise_mapping
    request.env["devise.mapping"] ||= Devise.mappings[:user]
  end
end

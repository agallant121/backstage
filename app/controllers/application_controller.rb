class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    allowed_keys = [
      :first_name, :last_name, :birthday, :spouse_name, :spouse_birthday,
      :home_address, :contact_notes,
      children_attributes: %i[id name birthday age notes _destroy]
    ]

    devise_parameter_sanitizer.permit(:sign_up, keys: allowed_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: allowed_keys)
  end
end

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || signed_in_root_path(resource)
  end

  def signed_in_root_path(resource)
    if resource.super_admin? || resource.event_admin? || resource.venue_admin?
      admin_root_path
    elsif resource.vendor_admin?
      vendor_root_path
    else
      root_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :company, :text_capable])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :company, :text_capable])
  end
end

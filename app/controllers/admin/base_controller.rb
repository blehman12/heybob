class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  private

  def ensure_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied.'
    end
  end

  def ensure_super_admin!
    unless current_user&.super_admin?
      redirect_to admin_root_path, alert: 'Super admin access required.'
    end
  end

  def ensure_can_manage_events!
    unless current_user&.can_manage_events?
      redirect_to admin_root_path, alert: 'Access denied.'
    end
  end

  def ensure_can_manage_venues!
    unless current_user&.can_manage_venues?
      redirect_to admin_root_path, alert: 'Access denied.'
    end
  end

  def ensure_can_manage_vendors!
    unless current_user&.can_manage_vendors?
      redirect_to admin_root_path, alert: 'Access denied.'
    end
  end
end

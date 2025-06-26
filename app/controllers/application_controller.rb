class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has()
  allow_browser versions: :modern

  # CSRF protection
  protect_from_forgery with: :exception

  # Devise helpers
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Check if user is admin
  def admin_user?
    user_signed_in? && current_user&.admin?
  end
  helper_method :admin_user?

  # CSP violation reporting endpoint for production security monitoring
  def csp_violation_report
    if Rails.env.production?
      Rails.logger.warn "CSP Violation: #{request.body.read}"
      # In production, you might want to send this to a monitoring service
      # like DataDog, Sentry, or similar
    end
    head :ok
  end

  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end

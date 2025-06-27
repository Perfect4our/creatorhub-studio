class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has()
  allow_browser versions: :modern

  # CSRF protection
  protect_from_forgery with: :exception

  # Devise helpers
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :track_user_activity, unless: :skip_activity_tracking?

  # Check if user is admin
  def admin_user?
    user_signed_in? && current_user&.admin?
  end
  helper_method :admin_user?

  # CSP violation reporting endpoint for production security monitoring
  skip_before_action :verify_authenticity_token, only: [:csp_violation_report]

  def csp_violation_report
    if Rails.env.production?
      Rails.logger.warn "CSP Violation: #{request.body.read}"
      # In production, you might want to send this to a monitoring service
      # like DataDog, Sentry, or similar
    end
    head :no_content
  end

  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def track_user_activity
    # Track real-time user activity for "Online Now" counter
    return unless current_user
    
    begin
      cache_key = "active_users"
      active_users = Rails.cache.read(cache_key) || {}
      
      # Add/update user with current timestamp
      active_users[current_user.id] = Time.current
      
      # Clean up users who haven't been active in the last 5 minutes
      cutoff_time = 5.minutes.ago
      active_users = active_users.select { |id, timestamp| timestamp > cutoff_time }
      
      # Store back in cache with 6 minute expiry
      Rails.cache.write(cache_key, active_users, expires_in: 6.minutes)
    rescue => e
      Rails.logger.error "User activity tracking error: #{e.message}"
      # Don't raise the error - just log it and continue
    end
  end

  def skip_activity_tracking?
    # Skip activity tracking for analytics endpoint to prevent potential loops
    (controller_name == 'analytics' && action_name == 'track_event') ||
    # Skip activity tracking for subscription deletion for maximum speed
    (controller_name == 'subscriptions' && action_name == 'destroy')
  end
end

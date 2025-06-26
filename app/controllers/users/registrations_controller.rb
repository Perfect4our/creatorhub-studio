class Users::RegistrationsController < Devise::RegistrationsController
  # Override create action to add PostHog tracking
  def create
    super do |resource|
      if resource.persisted?
        # Track successful signup server-side (critical event)
        PosthogService.track_signup(
          user: resource,
          source: params[:source] || 'web_signup'
        )
        
        # Also identify the user with initial properties
        PosthogService.identify_user(
          user_id: resource.id,
          properties: {
            email: resource.email,
            signup_date: resource.created_at.strftime('%Y-%m-%d'),
            signup_source: params[:source] || 'web_signup',
            user_role: resource.admin? ? 'admin' : 'user',
            has_permanent_subscription: resource.has_permanent_subscription?
          }
        )
        
        Rails.logger.info "🎯 User signup tracked via PostHog backend: #{resource.email}"
      end
    end
  end
  
  # Override update action to track profile updates
  def update
    super do |resource|
      if resource.errors.empty?
        # Track profile update
        PosthogService.track_event(
          user_id: resource.id,
          event: 'profile_updated_backend',
          properties: {
            email: resource.email,
            environment: Rails.env,
            server_tracked: true
          }
        )
      end
    end
  end
  
  # Override destroy action to track account deletion
  def destroy
    user_email = resource.email
    user_id = resource.id
    
    # Track account deletion before destroying the user
    PosthogService.track_event(
      user_id: user_id,
      event: 'account_deleted_backend',
      properties: {
        email: user_email,
        had_platforms_connected: resource.subscriptions.any?,
        platform_count: resource.subscriptions.count,
        was_subscribed: resource.stripe_subscribed?,
        environment: Rails.env,
        server_tracked: true
      }
    )
    
    super
  end
end 
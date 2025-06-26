# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  # Only enable CSP in production to avoid development issues
  if Rails.env.production?
    config.content_security_policy do |policy|
      policy.default_src :self, :https
      policy.font_src    :self, :https, :data
      policy.img_src     :self, :https, :data, :blob
      policy.object_src  :none
      
      # Production script sources with PostHog domains
      policy.script_src  :self, :https, 
                        "'unsafe-inline'", 
                        "'unsafe-eval'",
                        "https://cdn.jsdelivr.net",
                        "https://d3js.org", 
                        "https://cdnjs.cloudflare.com",
                        "https://app.posthog.com"
      
      # Style sources for external CSS libraries
      policy.style_src   :self, :https, 
                        "'unsafe-inline'",
                        "https://cdn.jsdelivr.net",
                        "https://cdnjs.cloudflare.com"
      
      # Connection sources for API calls and analytics
      policy.connect_src :self, :https,
                        "https://us.i.posthog.com",
                        "https://eu.i.posthog.com", 
                        "https://app.posthog.com"
      
      # Frame sources for embedded content
      policy.frame_src   :self, :https
      
      # Media sources for video/audio
      policy.media_src   :self, :https, :data, :blob
      
      # Worker sources for service workers
      policy.worker_src  :self, :blob
      
      # Manifest source for PWA
      policy.manifest_src :self
      
      # Violation reporting
      policy.report_uri "/csp-violation-report-endpoint"
    end

    # Use nonces for inline scripts in production for better security
    config.content_security_policy_nonce_generator = ->(request) { 
      SecureRandom.base64(32) 
    }
    config.content_security_policy_nonce_directives = %w(script-src style-src)
    
    # Enforce CSP in production
    config.content_security_policy_report_only = false
  else
    # Development: No CSP to avoid blocking issues
    Rails.logger.info "🔧 CSP disabled in development environment for easier debugging"
  end
end

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    
    # Production-ready script sources with specific PostHog domains
    policy.script_src  :self, :https, 
                      "'unsafe-inline'", 
                      "'unsafe-eval'",
                      "https://cdn.jsdelivr.net",
                      "https://d3js.org", 
                      "https://cdnjs.cloudflare.com",
                      "https://us-assets.i.posthog.com",
                      "https://app-static.eu.posthog.com",
                      "https://eu-assets.i.posthog.com"
    
    # Style sources for external CSS libraries
    policy.style_src   :self, :https, 
                      "'unsafe-inline'",
                      "https://cdn.jsdelivr.net",
                      "https://cdnjs.cloudflare.com"
    
    # Connection sources for API calls and analytics
    policy.connect_src :self, :https,
                      "https://us.i.posthog.com",
                      "https://eu.i.posthog.com", 
                      "https://app.posthog.com",
                      "wss://localhost:*",
                      "ws://localhost:*"
    
    # Frame sources for embedded content
    policy.frame_src   :self, :https
    
    # Media sources for video/audio
    policy.media_src   :self, :https, :data, :blob
    
    # Worker sources for service workers
    policy.worker_src  :self, :blob
    
    # Manifest source for PWA
    policy.manifest_src :self
    
    # Specify URI for violation reports in production
    if Rails.env.production?
      policy.report_uri "/csp-violation-report-endpoint"
    end
  end

  # Use nonces for inline scripts in production for better security
  config.content_security_policy_nonce_generator = ->(request) { 
    SecureRandom.base64(32) 
  }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Only report violations in development, enforce in production
  config.content_security_policy_report_only = Rails.env.development?
end

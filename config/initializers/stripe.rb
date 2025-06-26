Rails.application.configure do
  # Stripe Configuration
  if Rails.env.test?
    # Use placeholder key for tests
    Stripe.api_key = 'sk_test_placeholder_key'
  elsif Rails.env.development?
    # For development, use live keys (same as production for testing)
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key) ||
                     Rails.application.credentials.dig(:stripe, :test_secret_key) ||
                     ENV['STRIPE_SECRET_KEY'] || 
                     'sk_test_placeholder_key'
  else
    # Production uses encrypted credentials
    begin
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
      
      # Fallback to test key if live key not configured
      if Stripe.api_key.blank?
        Stripe.api_key = Rails.application.credentials.dig(:stripe, :test_secret_key)
        Rails.logger.warn "Using test Stripe key in production - configure live keys for production use"
      end
    rescue => e
      Rails.logger.error "Failed to load Stripe credentials: #{e.message}"
      Stripe.api_key = 'sk_test_placeholder_key'
    end
  end
  
  # Log the key being used (partially hidden for security)
  if Stripe.api_key.present? && !Stripe.api_key.include?('placeholder')
    masked_key = Stripe.api_key[0..7] + '...' + Stripe.api_key[-4..-1]
    Rails.logger.info "Stripe initialized with key: #{masked_key}"
  elsif Stripe.api_key.present? && Stripe.api_key.include?('placeholder')
    Rails.logger.warn "Stripe using placeholder key - configure real keys for full functionality"
  else
    Rails.logger.warn "Stripe API key is nil or blank - using fallback configuration"
    Stripe.api_key = 'sk_test_placeholder_key'
  end
end 
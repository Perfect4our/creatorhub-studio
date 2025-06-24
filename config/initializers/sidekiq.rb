require 'sidekiq'

# Configure Sidekiq
if Rails.env.development?
  # Use inline processing in development to avoid Redis dependency
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
  
  # Log that we're using inline mode
  Rails.logger.info "Sidekiq configured to run in inline mode for development"
else
  # Use Redis for production
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/1' }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/1' }
  end
end 
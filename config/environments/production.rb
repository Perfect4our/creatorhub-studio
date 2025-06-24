require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  
  # Explicitly set secret_key_base for production deployment
  # Try environment variable first, then fallback to a generated key
  config.secret_key_base = ENV['SECRET_KEY_BASE'] || 'ef6572c2e7298dd1777b74dc58a19afe93cb8763a57ec22dd0d334912c87bd5c4ea40ce1d9d4da3ee01e062e3a0755691857134e92e6aff22864ecfb98567807'

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV.fetch('RAILS_FORCE_SSL', 'true') == 'true'

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use Redis for caching in production
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
  }

  # Use Sidekiq for background jobs in production
  config.active_job.queue_adapter = :sidekiq

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { 
    host: ENV['CUSTOM_DOMAIN'] == 'true' ? 'creatorhubstudio.com' : ENV.fetch('HEROKU_APP_NAME', 'creatorhub-studio') + '.herokuapp.com',
    protocol: 'https'
  }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  if ENV['SMTP_ADDRESS'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: 587,
      domain: ENV.fetch('HEROKU_APP_NAME', 'creatorhub-studio') + '.herokuapp.com',
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: 'plain',
      enable_starttls_auto: true
    }
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # Allow Heroku domain
  config.hosts << /.*\.herokuapp\.com/
  config.hosts << "creatorhubstudio.com" if ENV['CUSTOM_DOMAIN']
  config.hosts << "www.creatorhubstudio.com" if ENV['CUSTOM_DOMAIN']

  # Asset pipeline configuration
  config.assets.compile = false
  config.assets.digest = true
  config.public_file_server.enabled = true

  # Action Cable configuration for production
  config.action_cable.allowed_request_origins = [
    /https:\/\/.*\.herokuapp\.com/,
    'https://creatorhubstudio.com',
    'https://www.creatorhubstudio.com'
  ]

  # Action Cable configuration for Rails 8
  config.action_cable.cable = {
    adapter: "redis",
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
  }
end

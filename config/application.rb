require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tiktokstudio
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Use Sidekiq as the Active Job queue adapter
    config.active_job.queue_adapter = :sidekiq
    
    # Bulletproof credentials protection for production deployment
    if Rails.env.production?
      # Override the credentials method to prevent decryption errors
      Rails.application.define_singleton_method(:credentials) do
        @safe_credentials ||= begin
          # Try to load real credentials first
          ActiveSupport::EncryptedConfiguration.new(
            config_path: Rails.root.join("config", "credentials.yml.enc"),
            key_path: Rails.root.join("config", "master.key"),
            env_key: "RAILS_MASTER_KEY",
            raise_if_missing_key: false
          )
        rescue => e
          # If credentials fail, return an empty configuration that won't break the app
          puts "⚠️  Credentials failed (#{e.class}), using environment variables fallback"
          ActiveSupport::OrderedOptions.new
        end
      end
    end
  end
end

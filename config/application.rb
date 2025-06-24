require_relative "boot"

require "rails/all"

# Load environment variables from .env file
require 'dotenv'
Dotenv.load

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
    
    # COMPLETELY BYPASS RAILS CREDENTIALS SYSTEM IN PRODUCTION
    if Rails.env.production?
      puts "🔒 Production: Bypassing Rails credentials system entirely"
      
      # Override the entire credentials system to prevent ANY decryption attempts
      define_method :credentials do
        @bypass_credentials ||= begin
          puts "📋 Using environment variables for all credentials"
          # Create a simple object that just returns environment variables
          credentials_obj = Object.new
          
          # Define all the methods we need
          credentials_obj.define_singleton_method(:dig) { |*keys| nil }
          
          # YouTube credentials from ENV
          credentials_obj.define_singleton_method(:youtube) do
            youtube_obj = Object.new
            youtube_obj.define_singleton_method(:api_key) { ENV['YOUTUBE_API_KEY'] }
            youtube_obj.define_singleton_method(:client_id) { ENV['YOUTUBE_CLIENT_ID'] }
            youtube_obj.define_singleton_method(:client_secret) { ENV['YOUTUBE_CLIENT_SECRET'] }
            youtube_obj
          end
          
          # TikTok credentials from ENV
          credentials_obj.define_singleton_method(:tiktok) do
            tiktok_obj = Object.new
            tiktok_obj.define_singleton_method(:client_id) { ENV['TIKTOK_CLIENT_ID'] }
            tiktok_obj.define_singleton_method(:client_secret) { ENV['TIKTOK_CLIENT_SECRET'] }
            tiktok_obj
          end
          
          # Catch any other method calls and return nil
          credentials_obj.define_singleton_method(:method_missing) { |*args| nil }
          credentials_obj.define_singleton_method(:respond_to_missing?) { |*args| true }
          
          credentials_obj
        end
      end
      
      # Also override the class method
      self.class.define_method(:credentials) do
        Rails.application.credentials
      end
    end
  end
end

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Ultra-aggressive credential protection for production deployment
# This prevents ANY credential access errors during Rails boot
if ENV['RAILS_ENV'] == 'production' || ENV['RACK_ENV'] == 'production'
  puts "🛡️  Activating production credential protection..."
  
  # Monkey patch Rails before it loads to prevent credential errors
  module CredentialSafety
    def credentials
      @safe_production_credentials ||= begin
        puts "🔑 Attempting to load Rails credentials..."
        super
      rescue => e
        puts "⚠️  Credentials failed: #{e.class} - #{e.message}"
        puts "✅ Using environment variable fallbacks"
        
        # Create a completely safe credentials object
        safe_creds = Object.new
        safe_creds.define_singleton_method(:dig) { |*keys| nil }
        safe_creds.define_singleton_method(:youtube) do
          youtube_creds = Object.new
          youtube_creds.define_singleton_method(:api_key) { ENV['YOUTUBE_API_KEY'] }
          youtube_creds.define_singleton_method(:client_id) { ENV['YOUTUBE_CLIENT_ID'] }
          youtube_creds.define_singleton_method(:client_secret) { ENV['YOUTUBE_CLIENT_SECRET'] }
          youtube_creds
        end
        safe_creds.define_singleton_method(:tiktok) do
          tiktok_creds = Object.new
          tiktok_creds.define_singleton_method(:client_id) { ENV['TIKTOK_CLIENT_ID'] }
          tiktok_creds.define_singleton_method(:client_secret) { ENV['TIKTOK_CLIENT_SECRET'] }
          tiktok_creds
        end
        safe_creds.define_singleton_method(:method_missing) { |*args| nil }
        safe_creds.define_singleton_method(:respond_to_missing?) { |*args| true }
        safe_creds
      end
    end
  end
  
  # Prepare to patch Rails::Application when it loads
  class << Object
    alias_method :original_const_missing, :const_missing
    
    def const_missing(name)
      result = original_const_missing(name)
      
      # Patch Rails::Application as soon as it's loaded
      if name == :Rails && defined?(Rails::Application)
        Rails::Application.prepend(CredentialSafety)
        puts "✅ Rails credential safety activated"
      end
      
      result
    end
  end
end

# Load the Rails application.
require_relative "application"

# NUCLEAR OPTION: Completely disable Rails encrypted credentials in production
if ENV['RAILS_ENV'] == 'production' || ENV['RACK_ENV'] == 'production'
  puts "🚫 PRODUCTION: Disabling Rails encrypted credentials entirely"
  
  # Override ActiveSupport::EncryptedConfiguration to never decrypt
  ActiveSupport::EncryptedConfiguration.class_eval do
    def read
      puts "📝 Intercepted credentials read - returning empty config"
      "{}"
    end
    
    def config
      @config ||= ActiveSupport::OrderedOptions.new
    end
  end
  
  # Override Rails.application.credentials at the class level
  Rails.singleton_class.class_eval do
    def application
      @application ||= super.tap do |app|
        app.define_singleton_method(:credentials) do
          @production_safe_credentials ||= begin
            puts "🔑 Using production environment variable credentials"
            safe_creds = Object.new
            
            # YouTube credentials
            safe_creds.define_singleton_method(:youtube) do
              yt = Object.new
              yt.define_singleton_method(:api_key) { ENV['YOUTUBE_API_KEY'] }
              yt.define_singleton_method(:client_id) { ENV['YOUTUBE_CLIENT_ID'] }
              yt.define_singleton_method(:client_secret) { ENV['YOUTUBE_CLIENT_SECRET'] }
              yt
            end
            
            # TikTok credentials
            safe_creds.define_singleton_method(:tiktok) do
              tt = Object.new
              tt.define_singleton_method(:client_id) { ENV['TIKTOK_CLIENT_ID'] }
              tt.define_singleton_method(:client_secret) { ENV['TIKTOK_CLIENT_SECRET'] }
              tt
            end
            
            # Safe methods
            safe_creds.define_singleton_method(:dig) { |*args| nil }
            safe_creds.define_singleton_method(:method_missing) { |*args| nil }
            safe_creds.define_singleton_method(:respond_to_missing?) { |*args| true }
            
            safe_creds
          end
        end
      end
    end
  end
end

# Initialize the Rails application.
Rails.application.initialize!

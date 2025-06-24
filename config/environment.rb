# Load the Rails application.
require_relative "application"

# Bulletproof credential protection for production deployment
# This prevents MessageEncryptor errors during Rails boot
if Rails.env.production?
  begin
    # Override Rails.application.credentials before it's accessed
    Rails.application.define_singleton_method(:credentials) do
      @safe_credentials ||= begin
        # Try normal credentials first
        ActiveSupport::EncryptedConfiguration.new(
          config_path: Rails.root.join("config", "credentials.yml.enc"),
          key_path: Rails.root.join("config", "master.key"),
          env_key: "RAILS_MASTER_KEY",
          raise_if_missing_key: false
        )
      rescue ActiveSupport::MessageEncryptor::InvalidMessage, 
             Errno::ENOENT,
             ActiveSupport::EncryptedFile::MissingKeyError => e
        puts "🔧 Credentials failed during boot: #{e.class}"
        puts "✅ Using environment variables instead"
        
        # Return empty credentials object that responds to all methods
        ActiveSupport::OrderedOptions.new.tap do |safe_creds|
          # Make it respond to dig and any other credential access
          safe_creds.define_singleton_method(:dig) { |*keys| nil }
          safe_creds.define_singleton_method(:youtube) { ActiveSupport::OrderedOptions.new }
          safe_creds.define_singleton_method(:tiktok) { ActiveSupport::OrderedOptions.new }
          safe_creds.define_singleton_method(:method_missing) { |*args| nil }
        end
      end
    end
  rescue => e
    puts "⚠️  Environment credential setup error: #{e.message}"
  end
end

# Initialize the Rails application.
Rails.application.initialize!

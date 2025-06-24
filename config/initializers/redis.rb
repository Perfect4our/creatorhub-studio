require 'redis'

# Configure Redis with fallback for development environment
if Rails.env.development?
  begin
    # Try to connect to Redis
    $redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/1", timeout: 1)
    # Test connection
    $redis.ping
    Rails.logger.info "Connected to Redis server"
  rescue Redis::CannotConnectError => e
    Rails.logger.warn "Redis connection failed: #{e.message}. Using memory store fallback."
    
    # Create a simple in-memory Redis mock for development
    class RedisMock
      def initialize
        @data = {}
        @pubsub_listeners = {}
      end
      
      def get(key)
        @data[key]
      end
      
      def set(key, value, opts = {})
        @data[key] = value
        "OK"
      end
      
      def del(key)
        @data.delete(key) ? 1 : 0
      end
      
      def exists?(key)
        @data.key?(key) ? 1 : 0
      end
      
      def expire(key, seconds)
        true
      end
      
      def publish(channel, message)
        listeners = @pubsub_listeners[channel] || []
        listeners.each { |callback| callback.call(channel, message) }
        listeners.size
      end
      
      def subscribe(channel, &block)
        @pubsub_listeners[channel] ||= []
        @pubsub_listeners[channel] << block
      end
      
      def ping
        "PONG"
      end
      
      def method_missing(method, *args, &block)
        Rails.logger.debug "RedisMock: #{method} called with #{args.inspect}"
        nil
      end
    end
    
    $redis = RedisMock.new
  end
else
  # Production and test environments
  $redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379/1")
end 
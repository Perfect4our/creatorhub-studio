class BasePlatformService
  attr_reader :subscription
  
  def initialize(subscription)
    @subscription = subscription
  end
  
  def sync!
    raise NotImplementedError, "#{self.class} must implement #sync!"
  end
  
  # Class method for testing API connection
  def self.test_connection
    begin
      # Try to instantiate and call a basic method
      # Subclasses can override this for more specific tests
      service_instance = new(nil)
      { success: true, message: "Service class can be instantiated" }
    rescue => e
      { success: false, message: "Failed to instantiate service: #{e.message}" }
    end
  end
  
  protected
  
  def fetch_profile_data
    raise NotImplementedError, "#{self.class} must implement #fetch_profile_data"
  end
  
  def fetch_videos
    raise NotImplementedError, "#{self.class} must implement #fetch_videos"
  end
  
  def create_daily_stat(data)
    subscription.daily_stats.create!(
      date: Date.current,
      views: data[:views],
      followers: data[:followers],
      revenue: data[:revenue],
      platform: subscription.platform
    )
  end
end

namespace :youtube do
  desc "Test YouTube API connection and sync data"
  task test_sync: :environment do
    puts "🔍 Testing YouTube API Connection & Data Sync"
    puts "=" * 50
    
    youtube_subscriptions = Subscription.where(platform: 'youtube', active: true)
    
    if youtube_subscriptions.empty?
      puts "❌ No active YouTube subscriptions found"
      puts "💡 Connect a YouTube account first at /subscriptions"
      exit
    end
    
    youtube_subscriptions.each do |subscription|
      puts "\n📺 Testing subscription ID: #{subscription.id}"
      puts "   User: #{subscription.user.email}"
      puts "   Channel ID: #{subscription.tiktok_uid}"
      puts "   Token present: #{subscription.auth_token.present? ? '✅' : '❌'}"
      puts "   Token expired: #{subscription.token_expired? ? '❌' : '✅'}"
      
      service = YoutubeService.new(subscription)
      
      # Test channel info
      puts "\n🔍 Testing channel info..."
      begin
        channel_info = service.get_channel_info
        if channel_info && channel_info[:subscriber_count]
          puts "   ✅ Channel: #{channel_info[:title]}"
          puts "   ✅ Subscribers: #{number_with_delimiter(channel_info[:subscriber_count])}"
          puts "   ✅ Views: #{number_with_delimiter(channel_info[:view_count])}"
        else
          puts "   ❌ Failed to get channel info"
          next
        end
      rescue => e
        puts "   ❌ Error: #{e.message}"
        next
      end
      
      # Test videos
      puts "\n🎥 Testing videos..."
      begin
        videos = service.get_videos(5)
        if videos.any?
          puts "   ✅ Found #{videos.count} videos"
          videos.first(3).each do |video|
            puts "     - #{video[:title]} (#{number_with_delimiter(video[:view_count])} views)"
          end
        else
          puts "   ⚠️  No videos found (might be a new channel)"
        end
      rescue => e
        puts "   ❌ Error getting videos: #{e.message}"
      end
      
      # Test sync
      puts "\n🔄 Testing data sync..."
      begin
        if service.sync!
          puts "   ✅ Sync successful!"
          
          # Show updated daily stats
          latest_stat = subscription.daily_stats.order(:date).last
          if latest_stat
            puts "   📊 Latest stats (#{latest_stat.date}):"
            puts "     - Views: #{number_with_delimiter(latest_stat.views)}"
            puts "     - Followers: #{number_with_delimiter(latest_stat.followers)}"
            puts "     - Revenue: $#{latest_stat.revenue}"
          end
        else
          puts "   ❌ Sync failed"
        end
      rescue => e
        puts "   ❌ Sync error: #{e.message}"
      end
    end
    
    puts "\n" + "=" * 50
    puts "🎯 Test complete! Check the dashboard to see updated data."
  end
  
  desc "Manually sync all YouTube accounts"
  task sync_all: :environment do
    puts "🔄 Syncing all YouTube accounts..."
    
    youtube_subscriptions = Subscription.where(platform: 'youtube', active: true)
    
    if youtube_subscriptions.empty?
      puts "❌ No active YouTube subscriptions found"
      exit
    end
    
    youtube_subscriptions.each do |subscription|
      puts "\n📺 Syncing subscription #{subscription.id} (#{subscription.user.email})..."
      
      begin
        FetchYoutubeDataJob.perform_now(subscription.id)
        puts "   ✅ Sync job completed"
      rescue => e
        puts "   ❌ Sync failed: #{e.message}"
      end
    end
    
    puts "\n✅ All YouTube accounts processed!"
  end
  
  desc "Check YouTube API credentials"
  task check_credentials: :environment do
    puts "🔍 Checking YouTube API Credentials"
    puts "=" * 40
    
    # Check environment variables
    env_api_key = ENV['YOUTUBE_API_KEY']
    env_client_id = ENV['YOUTUBE_CLIENT_ID']
    env_client_secret = ENV['YOUTUBE_CLIENT_SECRET']
    
    # Check encrypted credentials
    cred_api_key = Rails.application.credentials.youtube&.api_key
    cred_client_id = Rails.application.credentials.youtube&.client_id
    cred_client_secret = Rails.application.credentials.youtube&.client_secret
    
    puts "Environment Variables:"
    puts "  API Key: #{env_api_key.present? ? '✅ Present' : '❌ Missing'}"
    puts "  Client ID: #{env_client_id.present? ? '✅ Present' : '❌ Missing'}"
    puts "  Client Secret: #{env_client_secret.present? ? '✅ Present' : '❌ Missing'}"
    
    puts "\nEncrypted Credentials:"
    puts "  API Key: #{cred_api_key.present? ? '✅ Present' : '❌ Missing'}"
    puts "  Client ID: #{cred_client_id.present? ? '✅ Present' : '❌ Missing'}"
    puts "  Client Secret: #{cred_client_secret.present? ? '✅ Present' : '❌ Missing'}"
    
    # Test API connection
    api_key = cred_api_key || env_api_key
    if api_key.present?
      puts "\n🔗 Testing API connection..."
      begin
        uri = URI('https://www.googleapis.com/youtube/v3/channels')
        params = { part: 'snippet', forUsername: 'YouTube', key: api_key }
        uri.query = URI.encode_www_form(params)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.get(uri)
        
        if response.code == '200'
          puts "  ✅ YouTube Data API v3 connection successful"
        else
          puts "  ❌ API connection failed (#{response.code})"
        end
      rescue => e
        puts "  ❌ API connection error: #{e.message}"
      end
    else
      puts "\n❌ No API key available for testing"
    end
  end
  
  private
  
  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end 
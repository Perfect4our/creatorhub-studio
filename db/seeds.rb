# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user
admin = User.where(email: 'admin@example.com').first_or_initialize
admin.assign_attributes(
  password: 'password',
  password_confirmation: 'password',
  admin: true,
  name: 'Admin User'
)
admin.save!
puts "Admin user created or updated: #{admin.email}"

# Create regular user
user = User.where(email: 'user@example.com').first_or_initialize
user.assign_attributes(
  password: 'password',
  password_confirmation: 'password',
  name: 'Regular User'
)
user.save!
puts "Regular user created or updated: #{user.email}"

# Create subscriptions for different platforms
platforms = ['tiktok', 'youtube', 'instagram', 'twitter', 'facebook', 'linkedin', 'twitch']

platforms.each_with_index do |platform, index|
  subscription = Subscription.where(user: user, platform: platform).first_or_initialize
  subscription.assign_attributes(
    tiktok_uid: "#{platform}_uid_#{index}",
    auth_token: "auth_token_#{index}",
    refresh_token: "refresh_token_#{index}",
    expires_at: 30.days.from_now,
    active: true
  )
  subscription.save!
  puts "Subscription created or updated for platform: #{platform}"
  
  # Create daily stats for the past 7 days
  7.downto(0) do |days_ago|
    date = days_ago.days.ago.to_date
    
    # Generate random stats with an upward trend
    views_base = rand(1000..10000)
    followers_base = rand(100..5000)
    revenue_base = rand(10..500)
    
    # Add some growth each day
    growth_factor = 1.0 + (7 - days_ago) * 0.03
    
    daily_stat = DailyStat.where(subscription: subscription, date: date).first_or_initialize
    daily_stat.assign_attributes(
      views: (views_base * growth_factor).to_i,
      followers: (followers_base * growth_factor).to_i,
      revenue: (revenue_base * growth_factor).round(2),
      platform: platform
    )
    daily_stat.save!
    puts "Daily stat created or updated for #{platform} on #{date}"
  end
  
  # For TikTok, create some videos
  if platform == 'tiktok'
    10.times do |i|
      created_at = rand(1..30).days.ago
      
      video = TikTokVideo.where(subscription: subscription, video_id: "video_#{i}_#{Time.now.to_i}").first_or_initialize
      video.assign_attributes(
        title: "TikTok Video ##{i}",
        view_count: rand(1000..100000),
        like_count: rand(100..10000),
        comment_count: rand(10..1000),
        share_count: rand(5..500),
        created_at_tiktok: created_at,
        thumbnail_url: "https://placehold.co/320x180?text=TikTok+#{i}"
      )
      video.save!
      puts "TikTok video created or updated: #{video.title}"
    end
  end
end

puts "Seed data created successfully!"

namespace :live_stats do
  desc "Broadcast live stats to all users"
  task broadcast: :environment do
    puts "Broadcasting live stats to all users..."
    
    User.find_each do |user|
      puts "Broadcasting to user #{user.id} (#{user.email})..."
      LiveStatsBroadcastJob.perform_now(user.id)
    end
    
    puts "Done!"
  end
  
  desc "Start periodic broadcasting (runs in foreground)"
  task start_periodic: :environment do
    puts "Starting periodic broadcasting of live stats..."
    puts "Press Ctrl+C to stop"
    
    loop do
      User.find_each do |user|
        puts "Broadcasting to user #{user.id} (#{user.email})..."
        LiveStatsBroadcastJob.perform_now(user.id)
      end
      
      puts "Sleeping for 10 seconds..."
      sleep 10
    end
  end
end

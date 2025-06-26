namespace :admin do
  desc "Make a user an admin"
  task :create, [:email] => :environment do |task, args|
    email = args[:email] || 'perfect4ouryt@gmail.com'
    
    user = User.find_by(email: email)
    if user
      user.update!(admin: true)
      puts "✅ Successfully made #{email} an admin!"
      puts "User details: ID=#{user.id}, Email=#{user.email}, Admin=#{user.admin?}, Name=#{user.name}"
    else
      puts "❌ User with email #{email} not found"
      puts "Available users:"
      User.all.each { |u| puts "- #{u.email} (admin: #{u.admin?})" }
    end
  end
end 
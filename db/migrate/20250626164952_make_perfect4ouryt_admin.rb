class MakePerfect4ourytAdmin < ActiveRecord::Migration[8.0]
  def up
    user = User.find_by(email: 'perfect4ouryt@gmail.com')
    if user
      user.update!(admin: true)
      puts "✅ Made #{user.email} an admin"
    else
      puts "❌ User perfect4ouryt@gmail.com not found"
    end
  end

  def down
    user = User.find_by(email: 'perfect4ouryt@gmail.com')
    if user
      user.update!(admin: false)
      puts "❌ Removed admin from #{user.email}"
    end
  end
end 
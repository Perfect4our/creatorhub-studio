class AllowMultipleAccountsPerPlatform < ActiveRecord::Migration[8.0]
  def change
    # Add account name to distinguish between multiple accounts
    add_column :subscriptions, :account_name, :string
    add_column :subscriptions, :account_username, :string
    add_column :subscriptions, :channel_id, :string
    
    # Remove the unique constraint on tiktok_uid to allow multiple accounts
    remove_index :subscriptions, :tiktok_uid if index_exists?(:subscriptions, :tiktok_uid)
    
    # Add a composite unique constraint: user + platform + channel_id
    # This allows multiple accounts per platform per user, but prevents duplicates
    add_index :subscriptions, [:user_id, :platform, :channel_id], unique: true, name: 'index_subscriptions_on_user_platform_channel'
    
    # Add index for faster lookups
    add_index :subscriptions, [:user_id, :platform], name: 'index_subscriptions_on_user_platform'
  end
end

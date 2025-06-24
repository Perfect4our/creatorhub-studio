class AddTikTokAuthFieldsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :refresh_token, :string
    add_column :subscriptions, :expires_at, :datetime
    add_column :subscriptions, :scope, :string
  end
end

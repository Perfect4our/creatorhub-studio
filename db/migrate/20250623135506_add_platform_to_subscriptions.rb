class AddPlatformToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :platform, :string
  end
end

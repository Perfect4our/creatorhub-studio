class AddSubscriptionStatusAcknowledgedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_status_acknowledged_at, :datetime
  end
end

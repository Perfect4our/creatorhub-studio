class AddPermanentSubscriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :permanent_subscription, :boolean, default: false, null: false
  end
end

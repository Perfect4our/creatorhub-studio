class AddStripeSubscriptionIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stripe_subscription_id, :string
  end
end

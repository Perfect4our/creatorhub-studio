class AddBillingViewedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :billing_viewed_at, :datetime
  end
end

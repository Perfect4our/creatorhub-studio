class AddStripeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :subscription_status, :string
    add_column :users, :current_period_end, :datetime
    add_column :users, :plan_name, :string
  end
end

class AddActiveToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :active, :boolean, default: true
  end
end

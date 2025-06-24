class AddEnableRealtimeToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :enable_realtime, :boolean, default: true
  end
end

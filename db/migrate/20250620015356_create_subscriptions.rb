class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tiktok_uid
      t.string :auth_token

      t.timestamps
    end
  end
end

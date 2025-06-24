class CreateDailyStats < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_stats do |t|
      t.references :subscription, null: false, foreign_key: true
      t.date :date
      t.integer :views
      t.integer :followers
      t.decimal :revenue
      t.string :platform

      t.timestamps
    end
  end
end

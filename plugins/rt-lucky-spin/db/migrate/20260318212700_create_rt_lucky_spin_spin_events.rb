# frozen_string_literal: true

class CreateRtLuckySpinSpinEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :rt_lucky_spin_spin_events do |t|
      t.integer :user_id, null: false
      t.date :grant_date
      t.integer :event_type, null: false
      t.integer :points
      t.string :product_prize_name
      t.datetime :awarded_at
      t.timestamps null: false
    end

    add_index :rt_lucky_spin_spin_events, %i[user_id created_at]
    add_index :rt_lucky_spin_spin_events, %i[user_id grant_date]
  end
end


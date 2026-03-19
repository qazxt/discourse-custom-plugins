# frozen_string_literal: true

class CreateRtLuckySpinWeeklyPrizes < ActiveRecord::Migration[7.0]
  def change
    create_table :rt_lucky_spin_weekly_prizes do |t|
      t.date :week_start_date, null: false
      t.string :prize_name, null: false
      t.integer :winner_user_id
      t.datetime :won_at
      t.integer :shipping_status, null: false, default: 0
      t.text :shipping_note
      t.timestamps null: false
    end

    add_index :rt_lucky_spin_weekly_prizes, %i[week_start_date prize_name], unique: true, name: "idx_rt_lucky_spin_weekly_unique_prize"
    add_index :rt_lucky_spin_weekly_prizes, %i[week_start_date winner_user_id], name: "idx_rt_lucky_spin_weekly_winner"
  end
end


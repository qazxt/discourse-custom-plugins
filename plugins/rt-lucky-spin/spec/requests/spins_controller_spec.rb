# frozen_string_literal: true

require "rails_helper"

RSpec.describe RtLuckySpin::SpinsController do
  fab!(:user) { Fabricate(:user) }

  before do
    SiteSetting.rt_lucky_spin_enabled = true
    SiteSetting.rt_lucky_spin_daily_grant_enabled = true

    # 保底产品奖：末尾窗口内（force_window）且本周无人中奖时，必出一次 product
    SiteSetting.rt_lucky_spin_product_prizes = "桌子"
    SiteSetting.rt_lucky_spin_product_prize_chance_per_mille = 1000
    SiteSetting.rt_lucky_spin_weekly_force_window_hours = 24 * 8

    # 其它奖励权重设为 1（此处不影响保底分支，但保持与讨论一致）
    SiteSetting.rt_lucky_spin_segment_points_1_weight = 1
    SiteSetting.rt_lucky_spin_segment_points_2_weight = 1
    SiteSetting.rt_lucky_spin_segment_points_3_weight = 1
    SiteSetting.rt_lucky_spin_segment_no_prize_weight = 1
  end

  it "guarantees a product prize in force window if none awarded" do
    freeze_time Time.zone.parse("2026-03-18 10:00:00") do
      sign_in(user)

      # 手动给一次抽奖次数，避免受登录触发时机影响
      RtLuckySpin::SpinEvent.create!(
        user_id: user.id,
        event_type: :daily_grant,
        grant_date: Date.current
      )

      post "/rt-lucky-spin/spin"
      expect(response.status).to eq(200)
      expect(response.parsed_body["type"]).to eq("product")

      ws = RtLuckySpin::WeeklyPrizePicker.week_start_date(Time.zone.now)
      weekly = RtLuckySpin::WeeklyPrize.where(week_start_date: ws, prize_name: "桌子").first
      expect(weekly&.winner_user_id).to eq(user.id)
    end
  end
end


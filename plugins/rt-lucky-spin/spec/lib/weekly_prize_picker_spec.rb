# frozen_string_literal: true

require "rails_helper"

RSpec.describe RtLuckySpin::WeeklyPrizePicker do
  fab!(:user) { Fabricate(:user) }

  before do
    SiteSetting.rt_lucky_spin_enabled = true
    SiteSetting.rt_lucky_spin_daily_grant_enabled = true
    SiteSetting.rt_lucky_spin_product_prizes = "A\nB\n"
    SiteSetting.rt_lucky_spin_product_prize_chance_per_mille = 1000
    SiteSetting.rt_lucky_spin_weekly_deadline_wday = 0
    SiteSetting.rt_lucky_spin_weekly_deadline_hour = 23
    SiteSetting.rt_lucky_spin_weekly_deadline_minute = 0
    SiteSetting.rt_lucky_spin_weekly_force_window_hours = 24
  end

  it "creates week start date on Monday" do
    now = Time.zone.parse("2026-03-18 12:00:00") # Wed
    expect(described_class.week_start_date(now)).to eq(Date.parse("2026-03-16")) # Mon
  end

  it "awards at most one winner per prize per week" do
    now = Time.zone.parse("2026-03-18 12:00:00")

    prize1 = described_class.pick_prize_for_spin!(user: user, now: now)
    expect(prize1).to be_present

    # keep picking until we exhaust available prizes
    other = Fabricate(:user)
    prizes = [prize1]
    10.times do
      p = described_class.pick_prize_for_spin!(user: other, now: now)
      prizes << p if p.present?
      break if prizes.uniq.size >= 2
    end

    # after both prizes are awarded, subsequent pick returns nil
    20.times { described_class.pick_prize_for_spin!(user: other, now: now) }
    expect(described_class.pick_prize_for_spin!(user: other, now: now)).to be_nil
  end
end


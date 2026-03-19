# frozen_string_literal: true

require "rails_helper"

RSpec.describe RtLuckySpin::DailyGrant do
  fab!(:user) { Fabricate(:user) }

  before do
    SiteSetting.rt_lucky_spin_enabled = true
    SiteSetting.rt_lucky_spin_daily_grant_enabled = true
  end

  it "grants once per day" do
    freeze_time Time.zone.parse("2026-03-18 10:00:00") do
      expect { described_class.grant_if_needed!(user) }.to change { RtLuckySpin::SpinEvent.count }.by(1)
      expect { described_class.grant_if_needed!(user) }.not_to change { RtLuckySpin::SpinEvent.count }
    end
  end
end


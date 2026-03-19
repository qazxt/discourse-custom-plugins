# frozen_string_literal: true

module ::RtLuckySpin
  module DailyGrant
    def self.grant_if_needed!(user)
      return unless SiteSetting.rt_lucky_spin_enabled
      return unless SiteSetting.rt_lucky_spin_daily_grant_enabled
      return if user.blank?

      today = Time.zone.today
      granted =
        RtLuckySpin::SpinEvent.exists?(
          user_id: user.id,
          event_type: RtLuckySpin::SpinEvent.event_types[:daily_grant],
          grant_date: today
        )
      return if granted

      RtLuckySpin::SpinEvent.create!(
        user_id: user.id,
        event_type: RtLuckySpin::SpinEvent.event_types[:daily_grant],
        grant_date: today
      )
    end
  end
end

DiscourseEvent.on(:user_logged_in) do |user|
  RtLuckySpin::DailyGrant.grant_if_needed!(user)
end


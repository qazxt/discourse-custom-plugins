# frozen_string_literal: true

module ::RtLuckySpin
  class WeeklyPrizePicker
    def self.week_start_date(now = Time.zone.now)
      # 周一作为一周开始
      (now.to_date - ((now.to_date.cwday - 1) % 7))
    end

    def self.deadline_at(now = Time.zone.now)
      start = week_start_date(now)
      wday = SiteSetting.rt_lucky_spin_weekly_deadline_wday.to_i
      hour = SiteSetting.rt_lucky_spin_weekly_deadline_hour.to_i
      minute = SiteSetting.rt_lucky_spin_weekly_deadline_minute.to_i

      # 将“周内星期几”映射到日期：wday(0=Sun..6=Sat)
      # cwday: Mon=1..Sun=7
      target_cwday = wday == 0 ? 7 : wday
      delta_days = (target_cwday - 1)
      Time.zone.local(start.year, start.month, start.day, 0, 0, 0) + delta_days.days + hour.hours + minute.minutes
    end

    def self.force_window?(now = Time.zone.now)
      force_hours = SiteSetting.rt_lucky_spin_weekly_force_window_hours.to_i
      return false if force_hours <= 0
      now >= (deadline_at(now) - force_hours.hours)
    end

    def self.ensure_week_rows!(week_start:, prize_names:)
      prize_names.each do |name|
        RtLuckySpin::WeeklyPrize.find_or_create_by!(week_start_date: week_start, prize_name: name)
      rescue ActiveRecord::RecordNotUnique
        # 并发下忽略
      end
    end

    def self.pick_prize_for_spin!(user:, now: Time.zone.now)
      prize_names = SiteSetting.rt_lucky_spin_product_prizes.to_s.lines.map(&:strip).reject(&:blank?)
      return nil if prize_names.empty?

      week_start = week_start_date(now)
      ensure_week_rows!(week_start: week_start, prize_names: prize_names)

      RtLuckySpin::WeeklyPrize.transaction do
        rows = RtLuckySpin::WeeklyPrize.lock.where(week_start_date: week_start, prize_name: prize_names)
        any_awarded = rows.where.not(winner_user_id: nil).exists?
        unawarded = rows.where(winner_user_id: nil).to_a
        return nil if unawarded.empty?

        should_award =
          force_window?(now) ? !any_awarded : SecureRandom.random_number(1000) < SiteSetting.rt_lucky_spin_product_prize_chance_per_mille.to_i

        return nil unless should_award

        chosen = unawarded.sample
        chosen.update!(winner_user_id: user.id, won_at: now)
        chosen.prize_name
      end
    end
  end
end


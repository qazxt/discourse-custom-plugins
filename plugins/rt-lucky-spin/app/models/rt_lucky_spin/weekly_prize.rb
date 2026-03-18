# frozen_string_literal: true

module ::RtLuckySpin
  class WeeklyPrize < ActiveRecord::Base
    self.table_name = "rt_lucky_spin_weekly_prizes"

    belongs_to :winner, class_name: "User", foreign_key: "winner_user_id", optional: true

    enum shipping_status: { pending: 0, shipped: 1, cancelled: 2 }

    validates :week_start_date, presence: true
    validates :prize_name, presence: true, length: { maximum: 200 }
  end
end


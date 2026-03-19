# frozen_string_literal: true

module ::RtLuckySpin
  class SpinEvent < ActiveRecord::Base
    self.table_name = "rt_lucky_spin_spin_events"

    belongs_to :user

    enum :event_type, {
      daily_grant: 0,
      spin_consumed: 1,
      spin_points: 2,
      spin_no_prize: 3,
      spin_product_prize: 4
    }

    validates :user_id, presence: true
    validates :event_type, presence: true
    validates :points, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  end
end


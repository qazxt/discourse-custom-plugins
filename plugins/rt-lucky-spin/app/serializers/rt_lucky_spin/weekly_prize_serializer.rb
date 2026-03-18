# frozen_string_literal: true

module ::RtLuckySpin
  class WeeklyPrizeSerializer < ApplicationSerializer
    attributes :id,
               :week_start_date,
               :prize_name,
               :winner_user_id,
               :winner_username,
               :won_at,
               :shipping_status,
               :shipping_note

    def winner_username
      object.winner&.username
    end
  end
end


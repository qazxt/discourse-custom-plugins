# frozen_string_literal: true

module ::RtLuckySpin
  class SpinEventSerializer < ApplicationSerializer
    attributes :id, :event_type, :points, :product_prize_name, :grant_date, :created_at
  end
end


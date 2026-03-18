# frozen_string_literal: true

module ::RtLuckySpin
  class SpinStateSerializer < ApplicationSerializer
    attributes :available_spins, :today_granted
  end
end


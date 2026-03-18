# frozen_string_literal: true

# name: rt-lucky-spin
# about: Daily login spin-to-win with points via Gamification
# version: 0.1.0
# authors: rt
# url: https://example.invalid/rt-lucky-spin

enabled_site_setting :rt_lucky_spin_enabled

register_asset "stylesheets/rt-lucky-spin.scss"

module ::RtLuckySpin
  PLUGIN_NAME = "rt-lucky-spin"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace RtLuckySpin
  end
end

require_relative "lib/rt_lucky_spin/engine"

after_initialize do
  module ::RtLuckySpin
    class Error < StandardError; end
  end

  require_relative "lib/rt_lucky_spin/gamification_adapter"
  require_relative "lib/rt_lucky_spin/daily_grant"
  require_relative "lib/rt_lucky_spin/weekly_prize_picker"
  require_relative "app/models/rt_lucky_spin/spin_event"
  require_relative "app/models/rt_lucky_spin/weekly_prize"
  require_relative "app/controllers/rt_lucky_spin/spins_controller"
  require_relative "app/controllers/rt_lucky_spin/admin_controller"
  require_relative "app/serializers/rt_lucky_spin/spin_event_serializer"
  require_relative "app/serializers/rt_lucky_spin/spin_state_serializer"
  require_relative "app/serializers/rt_lucky_spin/weekly_prize_serializer"

  RtLuckySpin::Engine.routes.draw do
    get "/state" => "spins#state"
    post "/spin" => "spins#spin"
    get "/history" => "spins#history"

    get "/admin/weekly" => "admin#weekly"
    put "/admin/weekly/:id/shipping" => "admin#update_shipping"
  end

  Discourse::Application.routes.append do
    mount ::RtLuckySpin::Engine, at: "/rt-lucky-spin"
  end
end


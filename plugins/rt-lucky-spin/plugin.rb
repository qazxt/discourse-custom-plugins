# frozen_string_literal: true

# name: rt-lucky-spin
# about: Daily login spin-to-win with points via Gamification
# version: 0.1.0
# authors: rt
# url: https://example.invalid/rt-lucky-spin

# 勿使用 enabled_site_setting：Discourse 会在关闭时整包不加载插件 JS，导致 *route-map* 未进 Router，
# 已登录用户从站内点到 /lucky-spin 会走 unknown → permalink-check found: false（页面不存在）。
# 开关仅用于业务：由 SiteSetting.rt_lucky_spin_enabled + 各控制器 ensure_enabled、侧栏 initializer 判断。
register_asset "stylesheets/rt-lucky-spin.scss"
register_site_setting_area "lucky_spin"

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
  require_relative "app/controllers/rt_lucky_spin/lucky_spin_html_controller"
  require_relative "app/serializers/rt_lucky_spin/spin_event_serializer"
  require_relative "app/serializers/rt_lucky_spin/spin_state_serializer"
  require_relative "app/serializers/rt_lucky_spin/weekly_prize_serializer"

  # HTML 外壳：Ember URL 在 Rails 侧必须有路由，否则直开 :3000 / 硬刷新会 Routing Error（permalink 仅匹配库中记录）
  Discourse::Application.routes.prepend do
    get "/lucky-spin" => "rt_lucky_spin/lucky_spin_html#index"
    get "/lucky-spin/admin" => "rt_lucky_spin/lucky_spin_html#admin"
  end

  Discourse::Application.routes.append do
    mount ::RtLuckySpin::Engine, at: "/rt-lucky-spin"
  end
end

